import { LightningElement, api, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import cometdlwc from '@salesforce/resourceUrl/cometd';
import getSessionId from '@salesforce/apex/C_SessionUtil.getSessionId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import currentUserId from '@salesforce/user/Id';

export default class PlatformEventToast extends LightningElement {
    @api recordId;
    libInitialized = false;
    @track sessionId;
    @track error;

    @api toastKeys;
    @api toastTitle;
    @api toastMessage;
    @api toastVariant;
    @api toastMode;
    @api runInSystemMode;

    @wire(getSessionId)
    wiredSessionId({ error, data }) {
        if (data) {
            console.log(data);
            this.sessionId = data;
            this.error = undefined;
            loadScript(this, cometdlwc)
            .then(() => {
                this.initializecometd()
            });
        } else if (error) {
            console.log(error);
            this.error = error;
            this.sessionId = undefined;
        }
    }

    connectedCallback() {
        console.log('recId ' + this.recordId);
    }

    initializecometd() {
        if (this.libInitialized) {
            return;
        }

        this.libInitialized = true;

        //inintializing cometD object/class
        var cometdlib = new window.org.cometd.CometD();
            
        //Calling configure method of cometD class, to setup authentication which will be used in handshaking
        cometdlib.configure({
            url: window.location.protocol + '//' + window.location.hostname + '/cometd/47.0/',
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
            appendMessageTypeToURL : false,
            logLevel: 'debug'
        });

        cometdlib.websocketEnabled = false;
        console.log('sessionId ' + this.sessionId);
        console.log('recId ' + this.recordId);
        cometdlib.handshake((status) => {
                
            if (status.successful) {
                // Successfully connected to the server.
                // Now it is possible to subscribe or send messages
                console.log('Successfully connected to server ' + currentUserId);
                cometdlib.subscribe('/event/ToastEvent__e', function (message) {
                    let toastData = message['data']['payload'];
                    console.log('subscribed to message!'+ toastData);
                    console.log(toastData);
                    /*console.log(this);
                    if(
                        toastData &&
                        toastData['Key__c'] &&
                        this.toastKeys.includes(toastData['Key__c']) &&
                        (
                            this.runInSystemMode ||
                            (toastData['CreatedById'] === currentUserId)
                        ) &&
                        (
                            toastData['RecordId__c'] && this.recordId ? toastData['RecordId__c'] === this.recordId : true
                        )
                    ) {
                        const toastEvent = new ShowToastEvent({
                            title: toastData['Title__c'] ? toastData['Title__c'] : this.toastTitle,
                            message: toastData['Message__c'] ? toastData['Message__c'] : this.toastMessage,
                            variant: toastData['Variant__c'] ? toastData['Variant__c'] : this.toastVariant,
                            mode: toastData['Mode__c'] ? toastData['Mode__c'] : this.toastMode
                        });
                        this.dispatchEvent(toastEvent);
                    }*/
                    if (toastData['CreatedById'] === currentUserId) {
                        const toastEvent = new ShowToastEvent({
                            title: toastData['Title__c'],
                            message: toastData['Message__c'],
                            variant: toastData['Variant__c'] ,
                            mode: toastData['Mode__c']
                        });
                        dispatchEvent(toastEvent);
                    }
                    
                });
            } else {
                /// Cannot handshake with the server, alert user.
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
        });
    }
}