import { LightningElement, api } from 'lwc';
import createLog from '@salesforce/apex/LC_UtilsController.createLog';
import createErrorLog from '@salesforce/apex/LC_UtilsController.createErrorLog';

export { showToast, showAlert, isEmpty, delay, minus, union, isNumeric, formatLabel, arraysAreEqual } from './ccgUtilsOther';
export { dynamicSort, sortData } from './ccgUtilsSort';
export { logInfo, logError, reduceErrors }  from './ccgUtilsLog';

import * as utils from './ccgUtilsLog';
import * as others from './ccgUtilsOther';

export default class CcgUtils extends LightningElement {
  // logger
  source = 'CCG Utils';
  @api 
  log = false;

  connectedCallback() {
    this.log = true;
  }

  @api
  createLog(process, subject, recordId, data) {
    try {
      let params = {
        process : process,
        subject : subject,
        recordId : recordId,
        data : data
      }
      utils.logInfo(this.log, this.source, 'createLog.params', params);

      createLog(params);
    } 
    catch (ex) {
      this.processError('createLog', ex);
    }    
  }
  
  @api
  async createErrorLog(process, subject, recordId, errorType, errorMessage, errorStack) {
    try {
      let params = {
        process : process,
        subject : subject,
        recordId : recordId,
        errorType : errorType,
        errorMessage : errorMessage,
        errorStack : errorStack
      }
      utils.logError(this.source, 'createErrorLog.params', params);

      await createErrorLog(params);
      return true;
    } 
    catch (ex) {
      this.processError('createErrorLog', ex);
      return false;
    }    
  }

  @api
  async processErrorCommon(parent, method, error, bCreateLogRecording = false, bAlert = true) {
    utils.logError(parent.source, method, error);
    utils.logError(parent.source, method, parent.errorMessage);

    if (bCreateLogRecording) {
      let recordId = (others.isEmpty(parent.recordId)) ? '' : parent.recordId;
      let process = await this.createErrorLog(parent.source, parent.subject, recordId, 'JavaScript Error', 
        parent.errorMessage[0], parent.errorMessage.join(','));

      if(process === false) return;
    }
    
    if (bAlert) {
      others.showAlert('Error', parent.errorMessage[0]);
    }
    else {
      others.showToast(parent, 'Error', parent.errorMessage[0], 'error'); 
    }    
  }

  async processError(method, error) {
    utils.logError(this.source, method, error);
    this.errorMessage = utils.reduceErrors(error);
    utils.logError(this.source, method, this.errorMessage);

    await others.showAlert('Error', this.errorMessage[0]);
  }
}