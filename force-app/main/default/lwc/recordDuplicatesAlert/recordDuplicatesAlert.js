import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecordDuplicates from '@salesforce/apex/C_Duplicates.getRecordDuplicates';
import ShowDuplicates from '@salesforce/label/c.ShowDuplicates';
import HideDuplicates from '@salesforce/label/c.HideDuplicates';
import PossibleDuplicates from '@salesforce/label/c.PossibleDuplicates';
import SVG_error from '@salesforce/resourceUrl/error';

export default class AccountDuplicatesLWC  extends NavigationMixin(LightningElement) {
    @api recordId;
    @track duplicateList;
    @track hasDuplicates = false;
    @track buttonTitle;
    @track error;
    @track record;
    label = {
      ShowDuplicates,
      HideDuplicates,
      PossibleDuplicates
    }
    svgErrorUrl = SVG_error;

  
   connectedCallback() {
      getRecordDuplicates({ recordId: this.recordId })
        .then(result => {
            this.duplicateList = JSON.parse(result).filter(item => item.Id !== this.recordId);
            if(this.duplicateList.length > 0) {
                this.hasDuplicates = true;
                this.buttonTitle = '(' + duplicateList.length +') Dublette(n) anzeigen';
            }
          
        })
        .catch(error => {
          console.error('error: ', error);
        });
    }

    showHideDuplicates(event){
        const target = this.template.querySelector('[data-id="duplicates"]');
        if(target.classList.contains('hide')){
            target.classList.remove('hide');
            target.classList.add('flex');
            event.target.label = this.label.HideDuplicates;
            event.target.iconName="utility:up";
        } else if(target.classList.contains('flex')){
            target.classList.remove('flex');
            target.classList.add('hide');
            event.target.label = this.label.ShowDuplicates;;
            event.target.iconName="utility:down";
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