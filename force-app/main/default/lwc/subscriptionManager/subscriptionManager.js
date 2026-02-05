import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountSubscriptions from '@salesforce/apex/SubscriptionController.getAccountSubscriptions';
import extendSubscription from '@salesforce/apex/SubscriptionController.extendSubscription';

// Column definitions for datatable
const COLUMNS = [
    { 
        label: 'Subscription Name', 
        fieldName: 'Name',
        type: 'text',
        cellAttributes: { class: { fieldName: 'rowClass' } }
    },
    { 
        label: 'Product', 
        fieldName: 'Name',
        type: 'text'
    },
    { 
        label: 'Status', 
        fieldName: 'Status__c',
        type: 'text',
        cellAttributes: {
            iconName: { fieldName: 'statusIcon' },
            iconPosition: 'left',
            class: { fieldName: 'statusClass' }
        }
    },
    { 
        label: 'Start Date', 
        fieldName: 'Start_Date__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }
    },
    { 
        label: 'End Date', 
        fieldName: 'End_Date__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }
    },
    { 
        label: 'Days Remaining', 
        fieldName: 'daysRemaining',
        type: 'number'
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: '⚡ Quick Extend (30 days)', name: 'extend' }
            ]
        }
    }
];

export default class SubscriptionManager extends LightningElement {
    
    // Properties
    @track accountId;
    @track subscriptions = [];
    @track isLoading = false;
    columns = COLUMNS;
    
    // Wire result holder for refresh
    wiredSubscriptionsResult;

    // Wire service to get subscriptions
    @wire(getAccountSubscriptions, { accountId: '$accountId' })
    wiredSubscriptions(result) {
        this.wiredSubscriptionsResult = result;
        
        if (result.data) {
            this.isLoading = false;
            
            // Process data to add computed fields
            this.subscriptions = result.data.map(sub => {
                const today = new Date();
                const endDate = new Date(sub.End_Date__c);
                const daysRemaining = Math.ceil((endDate - today) / (1000 * 60 * 60 * 24));
                
                // Determine status styling
                let statusIcon = 'utility:success';
                let statusClass = 'slds-text-color_success';
                let rowClass = '';
                
                if (sub.Status__c === 'Active') {
                    statusIcon = 'utility:success';
                    statusClass = 'slds-text-color_success';
                } else if (sub.Status__c === 'Expired') {
                    statusIcon = 'utility:error';
                    statusClass = 'slds-text-color_error';
                    rowClass = 'slds-text-color_weak';
                } else if (sub.Status__c === 'Replaced') {
                    statusIcon = 'utility:warning';
                    statusClass = 'slds-text-color_warning';
                    rowClass = 'slds-text-color_weak';
                }
                
                return {
                    ...sub,
                    daysRemaining: daysRemaining,
                    statusIcon: statusIcon,
                    statusClass: statusClass,
                    rowClass: rowClass
                };
            });
            
        } else if (result.error) {
            this.isLoading = false;
            this.showToast('Error', result.error.body.message, 'error');
            this.subscriptions = [];
        }
    }

    // Account selection handler
    handleAccountChange(event) {
        this.accountId = event.detail.recordId;
        this.isLoading = true;
    }

    // Handle row actions
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'extend') {
            this.handleExtend(row.Id, row.Name);
        }
    }

    // Extend subscription
    handleExtend(subscriptionId, subscriptionName) {
        this.isLoading = true;

        extendSubscription({ subscriptionId: subscriptionId })
            .then(() => {
                // Show success message
                this.showToast(
                    'Success',
                    `Subscription "${subscriptionName}" extended by 30 days!`,
                    'success'
                );

                // Refresh the data
                return refreshApex(this.wiredSubscriptionsResult);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast(
                    'Error',
                    error.body.message || 'Failed to extend subscription',
                    'error'
                );
            });
    }

    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Computed properties
    get hasSubscriptions() {
        return this.subscriptions && this.subscriptions.length > 0;
    }

    get noDataMessage() {
        if (!this.accountId) {
            return 'Please select an Account to view subscriptions';
        }
        return 'No subscriptions found for this Account';
    }

    get totalCount() {
        return this.subscriptions.length;
    }

    get activeCount() {
        return this.subscriptions.filter(sub => sub.Status__c === 'Active').length;
    }

    get expiredCount() {
        return this.subscriptions.filter(sub => sub.Status__c === 'Expired').length;
    }
}