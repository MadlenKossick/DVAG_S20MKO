/* APEX METHODS */
import startBatch from '@salesforce/apex/C_SharingJobScheduler.startBatch';
import addAgentSharingCalculations from '@salesforce/apex/C_SharingJobScheduler.addAgentSharingCalculations';
import addAccountSharingCalculations from '@salesforce/apex/C_SharingJobScheduler.addAccountSharingCalculations';

/* CUSTOM LABELS */
import SJE_Heading from '@salesforce/label/c.SJE_Heading';
import SJS_StartAgentCalculation from '@salesforce/label/c.SJS_StartAgentCalculation';
import SJS_StartAccountRelatedObjectCalculation from '@salesforce/label/c.SJS_StartAccountRelatedObjectCalculation';
import SJS_Success from '@salesforce/label/c.SJS_Success';
import SJS_Error from '@salesforce/label/c.SJS_Error';
import SJE_AccountIds from '@salesforce/label/c.SJE_AccountIds';
import SJE_UserIds from '@salesforce/label/c.SJE_UserIds';
import SJE_Add from '@salesforce/label/c.SJE_Add';
import SJE_IdPlaceHolder from '@salesforce/label/c.SJE_IdPlaceHolder';
import SJE_ConfirmAddCalculations from '@salesforce/label/c.SJE_ConfirmAddCalculations';

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SharingJobExecutor extends LightningElement {
    label = { SJE_Heading, SJS_StartAgentCalculation, SJS_StartAccountRelatedObjectCalculation, 
              SJS_Success, SJS_Error, SJE_AccountIds, SJE_UserIds, SJE_Add, SJE_IdPlaceHolder, 
              SJE_ConfirmAddCalculations };

    userIds = '';
    accountIds = '';

    handle_addUserIds(){
        if((this.userIds == '' && confirm(this.label.SJE_ConfirmAddCalculations)) || this.userIds != '') {
            this.addAgentSharingCalculations();
        }
    }
    
    handle_addAccountIds(){
        if((this.accountIds == '' && confirm(this.label.SJE_ConfirmAddCalculations)) || this.accountIds != '') {
            this.addAccountSharingCalculations();
        }     
    }

    addAgentSharingCalculations() {
        const param = { userIds : this.userIds };
        addAgentSharingCalculations(param)
            .then(result => {
                if(this.userIds == ''){
                    this.showToast('Batch', 'Started', 'success');
                }else{
                    this.showToast('AgentSharingCalculations', 'Added', 'success');
                }
            })
            .catch(error => {
                this.showToast(this.label.SJS_Error, error, 'error');
                console.log(error);
        });
    }

    addAccountSharingCalculations() {
        const param = { accountIds : this.accountIds };
        addAccountSharingCalculations(param)
            .then(result => {
                if(this.accountIds == ''){
                    this.showToast('Batch', 'Started', 'success');
                }else{
                    this.showToast('AccountSharingCalculations', 'Added', 'success');
                }
            })
            .catch(error => {
                this.showToast(this.label.SJS_Error, error, 'error');
                console.log(error);
        });
    }

    handleChange_UserIds(event) {
        this.userIds = event.target.value;
    }

    handleChange_AccountIds(event) {
        this.accountIds = event.target.value;
    }

    handle_startAgentBatch(){
        this.startBatch('Agent');
    }
  
    handle_startAccountRelatedObjectsBatch(){
        this.startBatch('360Objects');
    }

    startBatch(batchName) {
        const param = { batchName : batchName };
        startBatch(param)
            .then(result => {
                this.showToast('Batch', 'Started', 'success');
            })
            .catch(error => {
                this.showToast(this.label.SJS_Error, error, 'error');
                console.log(error);
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });  
        this.dispatchEvent(evt);  
     }
}