import { LightningElement, api, track, wire} from 'lwc';

import getHouseholdAccounts from '@salesforce/apex/LC_SetPrimaryHousehold.getHouseholdAccounts';
import manageRecords from '@salesforce/apex/LC_SetPrimaryHousehold.manageRecords';
import getLogSetting from '@salesforce/apex/LC_UtilsController.getLogSetting';

import action from '@salesforce/label/c.SPH_Action';
import save from '@salesforce/label/c.SPH_Save';
import cancel from '@salesforce/label/c.SPH_Cancel';
import loading from '@salesforce/label/c.SPH_Loading';
import error from '@salesforce/label/c.SPH_Error';
import norecordfound from '@salesforce/label/c.SPH_NoRecordFound';
import savemessage from '@salesforce/label/c.SPH_SaveMessage';
import norecordselected from '@salesforce/label/c.SPH_NoRecordSelected';

import * as utils from 'c/ccgUtils';

const COLUMNS = [
  { label: '', 
  fieldName : 'name', type: 'text', 
  wrapText: true, 
  hideDefaultActions: true}
];

export default class SetPrimaryHousehold extends LightningElement {
  // logger
  @api log;
  source = 'SetPrimaryHousehold';
  
  // table data
  columns = COLUMNS;
  @track data = [];
  allData = [];
  hasData = false;
  hideTableHeader = true;
  selectedRecord = '';
  oldRecord = '';
  acrwr;

  // component vars
  @api recordId;
  error;  
  errorMessage;
  showSpinner = false;
  
  label = {action, save, cancel, error, loading, norecordfound, savemessage, norecordselected};
    
  async connectedCallback() {
    this.log = await getLogSetting({'componentName':this.source});
    
    await this.getRecords();
    if (!this.hasData) {
      await utils.showAlert('', this.label.norecordfound, 'warning');
      this.handleCancel();
    }
  }
   
  renderedCallback() {
    if (!utils.isEmpty(this.oldRecord) && utils.isEmpty(this.selectedRecord)) {
      var el = this.template.querySelector('lightning-datatable');
      utils.logInfo(this.log, this.source, 'renderedCallback.oldRecord', this.oldRecord);
        
      if (this.allData.length == 1) {
        this.selectedRecord = this.oldRecord;
      }
      el.selectedRows = [this.oldRecord];      
    }
  }

  async getRecords() { 
    this.data = [];
    this.allData = [];
    this.hasData = false;
    this.acrwr = {};

    let params = {
      recordId : this.recordId
    }

    utils.logInfo(this.log, this.source, 'getRecords.params', params);

    this.enSpin();
    try {
      this.acrwr = await getHouseholdAccounts(params);
      utils.logInfo(this.log, this.source, 'getRecords.acrwr', this.acrwr);

      this.oldRecord = this.acrwr.recordIdPG;

      let result = this.acrwr.records;
      if (!utils.isEmpty(result)) {
        for (var i = 0; i < result.length; i++) {
          let name = result[i].name + ' (' + result[i].contacts.join(', ') + ')';
          this.data = [...this.data, {
            id: result[i].id,
            account: result[i].name,
            name: name,
            total: result[i].contacts.length
            }
          ];
        }
        this.data = utils.sortData('total', this.data, 'desc');
        this.allData = this.data;

        this.disSpin();
        if (!utils.isEmpty(this.allData)) this.hasData = true;
      }
    }
    catch(error) {
      this.processError('getRecords', error);
      this.disSpin();
    }

    utils.logInfo(this.log, this.source, 'getRecords.data', this.data);
  }

  // select one row only (in case we switch to check boxes)
  handleRowSelection(event) {
    var selectedRows = event.detail.selectedRows;
    var el = this.template.querySelector('lightning-datatable');
   
    if(selectedRows.length > 2) {      
      el.selectedRows = [];
    }
    else if(selectedRows.length > 1) {
      el.selectedRows = el.selectedRows.slice(1);
    }
    this.selectedRecord = el.selectedRows[0];
  }

  // callback from datatable filter
  handleFilterResults(event) {
    utils.logInfo(this.log, this.source, 'handleFilterResults.eventdetail', event.detail);
    if (event.detail.validTerm) {
      this.data = event.detail.filteredData;
    }
    else {
      this.data = this.allData;
    }
  }

  // process data in Apex controller  
  async handleSave() {
    utils.logInfo(this.log, this.source, 'handleSave.recordId', this.recordId);
    utils.logInfo(this.log, this.source, 'handleSave.selectedRecord', this.selectedRecord);

    if (utils.isEmpty(this.selectedRecord)) {
      await utils.showAlert(this.label.error, this.label.norecordselected);
      return;
    }
  
    let currentRecord = this.allData.filter(row => row.id === this.selectedRecord)[0];
    utils.logInfo(this.log, this.source, 'handleSave.currentRecord', currentRecord);
    
    this.enSpin();

    // set manageRecord params
    let params = {
      data : '',
      objType : 'AccountContactRelation',
      op : 'update'
    }
  
    try {
      if (!utils.isEmpty(this.oldRecord) && this.oldRecord == this.selectedRecord) {
        this.disSpin();    
        return;
      }
      else if (!utils.isEmpty(this.oldRecord)) {
        // update first to avoid validation errors FSCEC-2289
        await this.updateFinancialAccount();
        await this.updateInsurancePolicy();

        let recordClear = {
          Id : this.oldRecord,
          FinServ__PrimaryGroup__c : false
        };

        // update old record
        params.data = JSON.stringify(recordClear);

        utils.logInfo(this.log, this.source, 'handleSave.params clear', params);
        await manageRecords(params);
      }
      
      // update new record
      let record = {
        Id : currentRecord.id,
        FinServ__PrimaryGroup__c : true
      };
     
      params.data = JSON.stringify(record);
      utils.logInfo(this.log, this.source, 'handleSave.params update', params);
      await manageRecords(params);
           
      let message = utils.formatLabel(this.label.savemessage, [currentRecord.account]);
      this.disSpin();

      await utils.showAlert(this.label.save, message, 'success');
      this.handleCancel();
    }
    catch(error) {
      this.processError('getRecords', error);
      this.disSpin();
    }
  }

  async updateFinancialAccount() {
    if (utils.isEmpty(this.acrwr.financialAccounts)) return;

    let faccs = [];
    this.acrwr.financialAccounts.forEach(acc => {
      faccs.push({Id : acc.Id, PrimaryHouseholdHelper__c : this.recordId });
    });

    let params = {
      data : JSON.stringify(faccs),
      objType : 'List<FinServ__FinancialAccount__c>',
      op : 'update'
    }
    utils.logInfo(this.log, this.source, 'updateFinancialAccount', params);
    await manageRecords(params);
  }

  async updateInsurancePolicy() {
    if (utils.isEmpty(this.acrwr.insurancePolicies)) return; 

    let inpols = [];
    this.acrwr.insurancePolicies.forEach(pol => {
      inpols.push({Id : pol.Id, PrimaryHouseholdHelper__c : this.recordId });
    });

    let params = {
      data : JSON.stringify(inpols),
      objType : 'List<InsurancePolicy>',
      op : 'update'
    }

    utils.logInfo(this.log, this.source, 'updateInsurancePolicy', params);
    await manageRecords(params);
  }

  handleCancel() {
    const cancelEvent = new CustomEvent('cancelprocess', {});
    this.dispatchEvent(cancelEvent);
    // this.dispatchEvent(new CloseActionScreenEvent());
  }

  enSpin() {
    this.showSpinner = true;    
  }

  disSpin() {
    this.showSpinner = false;
  }

  async processError(method, error, bAlert = true) {
    console.error(error);
    this.error = error;
    utils.logError(this.source, method, error);
    
    this.errorMessage = utils.reduceErrors(error);
    utils.logError(this.source, method, this.errorMessage);
        
    if (bAlert) {
      utils.showAlert(this.label.error, this.errorMessage[0]);
    }
    else {
      utils.showToast(this, this.label.error, this.errorMessage[0], 'error'); 
    }    
  }
}