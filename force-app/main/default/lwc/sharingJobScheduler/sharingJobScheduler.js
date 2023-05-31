/* APEX METHODS */
import getCurrentlyScheduledCrons from '@salesforce/apex/C_SharingJobScheduler.getCurrentlyScheduledCrons';
import getJobHistory from '@salesforce/apex/C_SharingJobScheduler.getJobHistory';
import scheduleJob from '@salesforce/apex/C_SharingJobScheduler.scheduleJob';
import deleteScheduledJob from '@salesforce/apex/C_SharingJobScheduler.deleteScheduledJob';

/* CUSTOM LABELS */
import SJS_ScheduledJobs from '@salesforce/label/c.SJS_ScheduledJobs';
import SJS_JobHistory from '@salesforce/label/c.SJS_JobHistory';
import SJS_Heading from '@salesforce/label/c.SJS_Heading';
import SJS_StartAccountCalculation from '@salesforce/label/c.SJS_StartAccountCalculation';
import SJS_ScheduleJobs from '@salesforce/label/c.SJS_ScheduleJobs';
import SJS_Frequency from '@salesforce/label/c.SJS_Frequency';
import SJS_DeleteScheduledJob from '@salesforce/label/c.SJS_DeleteScheduledJob';
import SJS_Success from '@salesforce/label/c.SJS_Success';
import SJS_Error from '@salesforce/label/c.SJS_Error';
import SJS_SelectRecord from '@salesforce/label/c.SJS_SelectRecord';
import SJS_Status from '@salesforce/label/c.SJS_Status';
import SJS_PreviousFireTime from '@salesforce/label/c.SJS_PreviousFireTime';
import SJS_EndTime from '@salesforce/label/c.SJS_EndTime';
import SJS_NextFireTime from '@salesforce/label/c.SJS_NextFireTime';
import SJS_NumberOfErrors from '@salesforce/label/c.SJS_NumberOfErrors';
import SJS_CreatedDate from '@salesforce/label/c.SJS_CreatedDate';
import SJS_CompletedDate from '@salesforce/label/c.SJS_CompletedDate';
import SJS_StartAgreementCalculation from '@salesforce/label/c.SJS_StartAgreementCalculation';
import SJS_JobType from '@salesforce/label/c.SJS_JobType';
import SJS_Every5Minutes from '@salesforce/label/c.SJS_Every5Minutes';
import SJS_Every15Minutes from '@salesforce/label/c.SJS_Every15Minutes';
import SJS_Every30Minutes from '@salesforce/label/c.SJS_Every30Minutes';
import SJS_Account from '@salesforce/label/c.SJS_Account';
import SJS_Agreement from '@salesforce/label/c.SJS_Agreement';
import SJS_Name from '@salesforce/label/c.SJS_Name';
import SJS_Agent from '@salesforce/label/c.SJS_Agent';
import SJS_StartAgentCalculation from '@salesforce/label/c.SJS_StartAgentCalculation';
import SJS_StartAccountRelatedObjectCalculation from '@salesforce/label/c.SJS_StartAccountRelatedObjectCalculation';
import SJS_360Objects from '@salesforce/label/c.SJS_360Objects';

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SharingJobScheduler extends LightningElement {
   scheduledJobs = [];
   jobHistory = [];
   selectedScheduledJobs = [];

   disableScheduleJobs = true;
   disableDeleteJobs = true;
   selFrequency = '';
   selJobType = '';

   label = {   SJS_ScheduledJobs, SJS_JobHistory, SJS_Heading, SJS_StartAccountCalculation, SJS_ScheduleJobs,
               SJS_Frequency, SJS_DeleteScheduledJob, SJS_Success, SJS_Error, SJS_SelectRecord,
               SJS_Status, SJS_PreviousFireTime, SJS_EndTime, SJS_NextFireTime, SJS_NumberOfErrors, SJS_CreatedDate, 
               SJS_CompletedDate, SJS_StartAgreementCalculation, SJS_JobType, SJS_Every5Minutes, SJS_Every15Minutes, 
               SJS_Every30Minutes, SJS_Account, SJS_Agreement, SJS_Name, SJS_Agent, SJS_StartAgentCalculation, 
               SJS_StartAccountRelatedObjectCalculation, SJS_360Objects
            };

   frequencyOpts =  [
               { label: this.label.SJS_Every5Minutes, value: 'every5minutes' },
               { label: this.label.SJS_Every15Minutes, value: 'every15minutes' },
               { label: this.label.SJS_Every30Minutes, value: 'every30minutes' }
              ];

   jobTypeOpts =  [
               { label: this.label.SJS_Agent, value: 'agent' },
               { label: this.label.SJS_360Objects, value: '360Objects' }
               //{ label: this.label.SJS_Agreement, value: 'agreement' }
              ];

   columns_scheduledJobs = [
      { label: this.label.SJS_Status, fieldName: 'State' },
      { label: this.label.SJS_Name, fieldName: 'jobName' },
      { label: this.label.SJS_PreviousFireTime, fieldName: 'PreviousFireTime', type: 'date', typeAttributes:{ year: "numeric", month: "long", day: "2-digit", hour: "2-digit", minute: "2-digit"}},
      { label: this.label.SJS_NextFireTime, fieldName: 'NextFireTime', type: 'date', typeAttributes:{ year: "numeric", month: "long", day: "2-digit", hour: "2-digit", minute: "2-digit"} }
   ];
   
   columns_JobHistory = [
      { label: this.label.SJS_JobType, fieldName: 'ApexClassName' },
      { label: this.label.SJS_Status, fieldName: 'Status' },
      { label: this.label.SJS_NumberOfErrors, fieldName: 'NumberOfErrors' },
      { label: this.label.SJS_CreatedDate, fieldName: 'CreatedDate', type: 'date', typeAttributes:{ year: "numeric", month: "long", day: "2-digit", hour: "2-digit", minute: "2-digit"} },
      { label: this.label.SJS_CompletedDate, fieldName: 'CompletedDate', type: 'date', typeAttributes:{ year: "numeric", month: "long", day: "2-digit", hour: "2-digit", minute: "2-digit"} },
   ];

   connectedCallback(){
      this.refreshData();
   }

   refreshData(){
      this.getCurrentlyScheduledCrons();
      this.getJobHistory();
      this.selectedScheduledJobs = [];
      this.disableDeleteJobs = true;
   }

   getCurrentlyScheduledCrons() {
      const param = { cronJobName : '%Sharing%' };
      getCurrentlyScheduledCrons(param)
         .then(result => {
            console.log(result);
            let scheduledJobsList = [];
            result.forEach(function (value) {
               let schedJob = value;
               schedJob.jobName = value.CronJobDetail.Name;
               scheduledJobsList.push(value);
            });

            this.scheduledJobs = scheduledJobsList;
         })
         .catch(error => {
            this.showToast(this.label.SJS_Error, error, 'error');
            console.log(error);
      });
   }

   getJobHistory() {
      getJobHistory()
         .then(result => {
            console.log(result);
            this.jobHistory = result;
         })
         .catch(error => {
            this.showToast(this.label.SJS_Error, error, 'error');
            console.log(error);
      });
   }

   handle_changeFrequency(e){
      this.selFrequency = e.target.value;

      if(this.selFrequency != undefined && this.selFrequency != null && this.selFrequency != ''
         && this.selJobType != undefined && this.selJobType != null && this.selJobType != ''){
         this.disableScheduleJobs = false;
      }
   }

   handle_changeJobType(e){
      this.selJobType = e.target.value;

      if(this.selFrequency != undefined && this.selFrequency != null && this.selFrequency != ''
         && this.selJobType != undefined && this.selJobType != null && this.selJobType != ''){
         this.disableScheduleJobs = false;
      }
   }

   handle_scheduleJobs(){
      const param = { frequency : this.selFrequency, jobType: this.selJobType };
      scheduleJob(param)
         .then(result => {
            console.log(result);
            this.showToast(this.label.SJS_Success, this.label.SJS_ScheduleJobs, 'success');
            this.refreshData();
         })
         .catch(error => {
            this.showToast(this.label.SJS_Error, error, 'error');
            console.log(error);
      });
   }

   handle_deleteScheduleJobs(){
      console.log('delete jobs ' + this.selectedScheduledJobs);

      if(this.selectedScheduledJobs == undefined || this.selectedScheduledJobs == null || this.selectedScheduledJobs.length <= 0) {
         this.showToast(this.label.SJS_Error, this.label.SJS_SelectRecord, 'error');
         return;
      }

      let delJobIds = [];
      this.selectedScheduledJobs.forEach(function (value) {
         delJobIds.push(value.Id);
      });

      console.log(delJobIds);

      const param = { cronJobIds : delJobIds };
      deleteScheduledJob(param)
         .then(result => {
            console.log(result);
            this.showToast(this.label.SJS_Success, this.label.SJS_DeleteScheduledJob, 'success');

            this.refreshData();
         })
         .catch(error => {
            this.showToast(this.label.SJS_Error, error, 'error');
            console.log(error);
      });
   }

   handle_ScheduledJobsRowSelection(event){
      this.selectedScheduledJobs = event.detail.selectedRows;

      if(this.selectedScheduledJobs != undefined && this.selectedScheduledJobs != null && this.selectedScheduledJobs.length > 0) {
         this.disableDeleteJobs = false;
      }
      else {
         this.disableDeleteJobs = true;
      }
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