import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRSTNAME_FIELD from '@salesforce/schema/User.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/User.LastName';

export default class WelcomeMessage extends LightningElement {
    userId = USER_ID;
    fullName;

    @wire(getRecord, {
        recordId: '$userId',
        fields: [FIRSTNAME_FIELD, LASTNAME_FIELD]
    })
    user({ error, data }) {
        if (data) {
            this.fullName = `${data.fields.FirstName.value} ${data.fields.LastName.value}`;
        } else if (error) {
            console.error('Error retrieving user data', error);
        }
    }
}