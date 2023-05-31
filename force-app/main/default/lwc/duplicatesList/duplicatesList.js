import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Name from '@salesforce/label/et4ae5.name';
import Status from '@salesforce/label/et4ae5.status';
import Type from '@salesforce/label/c.Type';
import MainResidenceAddress from '@salesforce/label/c.MainResidenceAddress';
import Birthdate from '@salesforce/label/c.Birthdate';
import AccountCustomerNumber from '@salesforce/label/c.AccountCustomerNumber';
import ListSearch from '@salesforce/label/c.ListSearch';
import CollapseList from '@salesforce/label/c.CollapseList';
import ExpandList from '@salesforce/label/c.ExpandList';
import DuplicatesList from '@salesforce/label/c.DuplicatesList';
import getDuplicatesAccounts from '@salesforce/apex/C_Duplicates.getDuplicatesAccounts';


export default class App extends NavigationMixin(LightningElement) {

    label = {
      Name,
      Type,
      Status,
      MainResidenceAddress,
      Birthdate,
      AccountCustomerNumber,
      ListSearch,
      CollapseList,
      ExpandList,
      DuplicatesList
  }; 

    @track sortedDirection = 'asc';
    @track nameUpBool;
    @track nameDWBool;
    initRecord; 
    @track record;
    @api recordId ;
    @track iconName = 'utility:down';
    @track error;
    @wire(getDuplicatesAccounts)
    wiredRecord({ error, data }) {
        if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.record = undefined;

        } else if (data) {
            this.initRecord = data;
            this.record = data;
            this.groupArray(data, true);
        }
    }
    

    get duplicateGroupedArray(){
        return this.record;
    }
    groupArray(data, parse) {

        let array = parse==true ? JSON.parse(data) : data;
        let groupedDataMap = new Map();
        array.forEach(duplicate => {
            if (groupedDataMap.has(duplicate.groupName)) {
                groupedDataMap.get(duplicate.groupName).duplicates.push(duplicate);
            } else {
                let newDuplicate = {};
                newDuplicate.groupName = duplicate.name;
                newDuplicate.duplicates = [duplicate];
                groupedDataMap.set(duplicate.groupName, newDuplicate);
            }
        });
        let itr = groupedDataMap.values();
        let duplicateArray = [];
        let result = itr.next();
        while (!result.done) {
            result.value.rowspan = result.value.duplicates.length + 1;
            result.value.size = result.value.duplicates.length ;
            duplicateArray.push(result.value);
            result = itr.next();
        } 
        this.record = duplicateArray;
        this.sortArrays();
    }

    handleKeyChange(event) {
        const searchTerm = event.target.value.toLowerCase();;
        let map = JSON.parse(this.initRecord).filter(item => {
            console.log(item);
            return item.groupName.toLowerCase().includes(searchTerm)
                || item.status.toLowerCase().includes(searchTerm)
                || item.name.toLowerCase().includes(searchTerm)
        });
        this.groupArray(map, false);
      
    }

    sortArrays() {
        this.nameUpBool = false;
        this.nameDWBool = false;
        this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';   
        this.record.sort((a, b) => {
          if (this.sortedDirection === 'desc') {
            this.nameDWBool = true;
            if (a.groupName < b.groupName) {
              return -1;
            } else if (a.groupName > b.groupName) {
              return 1;
            } else {
              return 0;
            }
          } else {
            this.nameUpBool = true;
            if (a.groupName > b.groupName) {
              return -1;
            } else if (a.groupName < b.groupName) {
              return 1;
            } else {
              return 0;
            }
          }
        });
      }

   

    extend(event) {
        if (event.target.iconName == 'utility:down') {
            event.target.iconName = 'utility:up';
        } else {
            event.target.iconName = 'utility:down';
        }
        let targetId = event.target.dataset.id;
        let target = this.template.querySelectorAll(`[data-id="${targetId}"]`);
        target.forEach((value, index) => {
            if (index != 0) {
                if (value.classList.contains('hide')) {
                    value.classList.remove('hide');
                    value.classList.add('show');
                  } else if (value.classList.contains('show')) {
                    value.classList.remove('show');
                    value.classList.add('hide')
                  } 
            }
            
        });

    }

    removeClass(name){
        let target = this.template.querySelectorAll(`[class="${name}"]`);
        target.forEach((value, index) => {  
            if(name == 'hide'){
                value.classList.remove(name);
                value.classList.add('show');
            } else if(name == 'show'){
                value.classList.remove(name);
                value.classList.add('hide');
            }
                    
   
        });
    }


    handleMenuItem(event) {
        console.log("selected menu => " + event.detail.value);
        switch (event.detail.value) {
          case "Extend":
            this.removeClass('hide');
            break;
          case "Close":
            this.removeClass('show');
            break;
        }
      }

      openAccount(event) {
        const recordId = event.currentTarget.dataset.recordId;
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            recordId,
            objectApiName: 'Account',
            actionName: 'view'
          }
        });
      }
}