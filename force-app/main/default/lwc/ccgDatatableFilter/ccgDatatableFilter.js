import { LightningElement, track, api } from 'lwc';
import getLogSetting from '@salesforce/apex/LC_UtilsController.getLogSetting';

import * as utils from 'c/ccgUtils';

const SEARCH_DELAY = 500;

export default class ccgDatatableFilter extends LightningElement {
    // search
    @api placeholder = 'Search';
    @api allData = [];
    @api fieldsToFilterOn = [];
    @api label = '';
    @track noFields = false;
    searchTimeout;

    // logger
    source = 'CCGDatatableFilter';
    @api log = false;
        
    get labelIncluded(){
        return ( this.label === '' ? 'label-hidden' : ''); 
    }

    async connectedCallback() {
        // this.log = true;
        this.log = await getLogSetting({'componentName':this.source});
    }
    
    ensureFilterableFields(allData) {
        if(this.fieldsToFilterOn.length === 0 && allData.length !== 0){
            this.fieldsToFilterOn = Object.keys(allData[0]);
            return true;
        } 
        else if(this.fieldsToFilterOn.length === 0 ) {
            this.noFields = true;
            this.template.querySelector('lightning-input').value = '';
            utils.showToast(this, 'Search disabled', 'There are no fields to filter on', 'info')
            return false;
        }
        return true;
    }

    handleKeyUp(event) {
        if (event.key === 'Escape') {
            this.template.querySelector('lightning-input').value = '';
            let returnObj = {filteredData: [], searchTerm: '', validTerm:false}
            let searchResultFound = new CustomEvent('filtered', {detail: returnObj});
            this.dispatchEvent(searchResultFound);
        }
    }

    search(event){
        if (!this.ensureFilterableFields(this.allData)) return;
        
        if (this.searchTimeout) {
           clearTimeout(this.searchTimeout);
        }

        let searchFilter = event.target.value;
        utils.logInfo(this.log, this.source, 'search.searchFilter', searchFilter);

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchTimeout = setTimeout(() => {
            if(searchFilter.length <= 1){
                let returnObj = {filteredData: [], searchTerm: searchFilter, validTerm:false}
                let searchResultFound = new CustomEvent('filtered', {detail: returnObj});
                this.dispatchEvent(searchResultFound);
            } 
            else {
                this.filterData(searchFilter)
            }
            this.searchTimeout = null;     
        }, SEARCH_DELAY);
    }

    filterData(searchFilter) {
        let results; 

        try {
            results = this.getFilterData(this.allData, searchFilter);
            
            let returnObj = {filteredData: results, searchTerm: searchFilter, validTerm:true}
            let searchResultFound = new CustomEvent('filtered', {detail: returnObj});
            this.dispatchEvent(searchResultFound);
        } 
        catch (e) {
            console.error(e);
            this.data = [];
        }    
    }

    @api
    searchData(searchFilter, data) {
        let results; 

        try {
            if (!this.ensureFilterableFields(data)) return results;
            results = this.getFilterData(data, searchFilter);    
            
            return results;
        } 
        catch (e) {
            console.error(e);
            return results;
        }    
    }

    getFilterData(data, searchFilter) {
        // searches not case sensitive
        let regex = new RegExp(searchFilter, "i");

        let results = data.filter(row => {
            let matchFound = false;
            this.fieldsToFilterOn.forEach(filterFieldName => {
                if(regex.test(row[filterFieldName])) {
                    matchFound = true;
                }
            });
            return matchFound;
        });

        return results;
    }
}