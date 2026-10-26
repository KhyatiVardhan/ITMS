import { LightningElement , wire } from 'lwc';
import getOpenCasesCount from '@salesforce/apex/CaseSupportConsoleController.getOpenCasesCount';
import getSlaAtRiskCount from '@salesforce/apex/CaseSupportConsoleController.getSlaAtRiskCount';
import getSlaBreachedCount from '@salesforce/apex/CaseSupportConsoleController.getSlaBreachedCount';
import getResolvedTodayCount from '@salesforce/apex/CaseSupportConsoleController.getResolvedTodayCount';
import getFilteredCases from '@salesforce/apex/CaseSupportConsoleController.getFilteredCases';
import getFilteredCasesCount from '@salesforce/apex/CaseSupportConsoleController.getFilteredCasesCount';
import { refreshApex} from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJ from '@salesforce/schema/Case';
import caseCreateModal from 'c/caseCreateModal';
import caseEditModal from 'c/caseEditModal';

const PRIORITY_OPTIONS = [
    { label: 'All', value: 'All' },
    { label: 'High', value: 'High' },
    { label: 'Medium', value: 'Medium' },
    { label: 'Low', value: 'Low' }
];

const STATUS_OPTIONS = [
    { label: 'All', value: 'All' },
    { label: 'New', value: 'New' },
    { label: 'Working', value: 'Working' },
    { label: 'Escalated', value: 'Escalated' },
    { label: 'Closed', value: 'Closed' }
];

const ACTIONS = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit'}
];

const COLUMNS = [
    {label : 'Case Number' , fieldName : 'CaseNumber'},
    {label : 'Subject' , fieldName : 'Subject'},
    {label : 'Priority' , fieldName : 'Priority'},
    {label : 'Status' , fieldName : 'Status'},
    {label : 'Category' , fieldName : 'Ticket_Category__c'},
    {label : 'SLA Breached' , fieldName : 'SLA_Breached__c', type : 'boolean'},
    {label : 'SLA Status' , fieldName : 'slaStatus' , type : 'text' , 
        cellAttributes: {
            class: { fieldName: 'slaStatusClass' }
        }
    },
    {
        label: 'SLA Response',
        fieldName: 'SLA_Response_Due__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    {
        label: 'SLA Resolution',
        fieldName: 'SLA_Resolution_Due__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    },
    {
        type: 'action',
        typeAttributes: { rowActions: ACTIONS },
    }
];

export default class CaseSupportConsole extends NavigationMixin(LightningElement) {

    columns = COLUMNS;
    cases = [];
    wiredCasesCountResult = null;
    wiredSlaAtRiskCountResult = null;
    wiredSlaBreachedCountResult = null;
    wiredCasesResolvedTodayCountResult = null;
    wiredFilterCasesResult = null;
    error = null;
    countError = null;
    slaAtRiskCountError = null;
    slaBreachedCountError = null;
    resolvedTodayCountError = null;
    isLoading = true;
    priorityOps = PRIORITY_OPTIONS;
    statusOps = STATUS_OPTIONS;
    priorityValue = 'All';
    statusValue = 'All';
    pageSize = 50;
    offsetValue = 0;
    wiredFilterCasesCountResult = null;
    filteredCasesCountError = null;

    filterParams = {
        priority : 'All',
        status : 'All',
        pageSize : 50,
        offsetValue : 0
    }

    @wire(getFilteredCases , {
        request : '$filterParams'
    })
    wiredFilteredCases(result){
        this.wiredFilterCasesResult = result;
        if(result.data !== undefined){
            this.cases = result.data.map(caseRecord => {
                const slaStatus = this.getSlaStatus(caseRecord);

                return {
                    ...caseRecord,
                    slaStatus: slaStatus,
                    slaStatusClass: this.getSlaStatusClass(slaStatus)
                };
            });
            this.error = null;
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.cases = [];
            this.isLoading = false;
        }
    }

    @wire(getFilteredCasesCount , { request : '$filterParams'})
    wiredFilterCasesCount(result){
        console.log('Filtered count wire executed', result);
        this.wiredFilterCasesCountResult = result;
        if(result.data !== undefined){
            console.log('Filtered Cases Count:', result.data);
            this.filteredCasesCountError = null;
        } else if (result.error) {
            console.error('Filtered Count Error:', JSON.stringify(result.error));
            this.filteredCasesCountError = result.error;
        }
    }

    @wire(getOpenCasesCount)
    wiredCasesCount(result){
        this.wiredCasesCountResult = result;
        if(result.data !== undefined){
            this.countError = null;
        } else if(result.error){
            this.countError = result.error;
        }
    }

    @wire(getSlaAtRiskCount)
    wiredSlaAtRiskCount(result){
        this.wiredSlaAtRiskCountResult = result;
        if(result.data !== undefined){
            this.slaAtRiskCountError = null;
        }
        else if(result.error){
            this.slaAtRiskCountError = result.error;
        }
    }

    @wire(getSlaBreachedCount)
    wiredSlaBreachedCount(result){
        this.wiredSlaBreachedCountResult = result;
        if(result.data !== undefined){
            this.slaBreachedCountError = null;
        }
        else if(result.error){
            this.slaBreachedCountError = result.error;
        }
    }

    @wire(getResolvedTodayCount)
    wiredResolvedTodayCount(result){
        this.wiredCasesResolvedTodayCountResult = result;
        if(result.data !== undefined){
            this.resolvedTodayCountError = null;
        }
        else if(result.error){
            this.resolvedTodayCountError = result.error;
        }
    }

    getSlaStatusClass(status) {
        switch (status) {
            case 'Breached':
                return 'slds-text-color_error';
            case 'At Risk':
                return 'slds-text-color_warning';
            case 'On Track':
                return 'slds-text-color_success';
            case 'Closed':
                return 'slds-text-color_weak';
            default:
                return '';
        }
    }

    get casesResolvedTodayCount(){
        return this.wiredCasesResolvedTodayCountResult?.data ?? 0;
    }

    get slaBreachedCount(){
        return this.wiredSlaBreachedCountResult?.data ?? 0;
    }

    get slaAtRiskCount(){
        return this.wiredSlaAtRiskCountResult?.data ?? 0;
    }

    get caseCount(){
        return this.wiredCasesCountResult?.data ?? 0;
    }

    get hasCases(){
        return this.cases && this.cases.length > 0;
    }

    get hasNoCases(){
        return !this.isLoading && !this.error && this.cases.length === 0;
    }

    get errorMessage(){
        return this.error?.body?.message || this.error?.message || 'An unknown error occurred while fetching cases.';
    }

    async handleRefresh(){
        console.log('Refreshing cases...');
        this.isLoading = true;
        this.error = null;
        try {
            await Promise.all([
                refreshApex(this.wiredFilterCasesResult),
                refreshApex(this.wiredCasesCountResult),
                refreshApex(this.wiredSlaAtRiskCountResult),
                refreshApex(this.wiredSlaBreachedCountResult),
                refreshApex(this.wiredCasesResolvedTodayCountResult),
                refreshApex(this.wiredFilterCasesCountResult)
            ]);
        }
        catch(error){
            console.error('Error refreshing dashboard data:', error);
        }
        finally {
            this.isLoading = false;
        }
    }

    handleRowAction(event){
        const actionName = event.detail.action.name;
        const caseId = event.detail.row.Id;
        if(actionName === 'view'){
            this.navigateToCaseDetail(caseId);
        }
        if(actionName === 'edit'){
            this.handleEditAction(caseId);
        }
    }

    async handleEditAction(caseId){
        const result = await caseEditModal.open({
                header : 'Edit Case',
                recordId : caseId
            });
            if(result === 'success'){
                this.handleRefresh();
            }
        }

    navigateToCaseDetail = (caseId)=>{
        this[NavigationMixin.GenerateUrl]({
            type : 'standard__recordPage',
            attributes : {
                recordId : caseId,
                objectApiName : CASE_OBJ.objectApiName,
                actionName : 'view'
            }
        })
        .then((generateUrl)=>{
            window.open(generateUrl, '_blank');
        })
        .catch((error) => {
            console.error('Error generating navigation URL:', error);
        })
    }

    handleChangeFilter(event){
        const actionName = event.target.name;
        const selectedValue = event.detail.value;
        if(actionName === 'priority'){
            this.priorityValue = selectedValue;
        }
        else if(actionName === 'status'){
            this.statusValue = selectedValue;
        }

        this.offsetValue = 0;
        this.isLoading = true;
        this.filterParams = {
            priority: this.priorityValue,
            status: this.statusValue,
            pageSize: this.pageSize,
            offsetValue: this.offsetValue
        };
    }

    get filteredCasesCount() {
        return this.wiredFilterCasesCountResult?.data ?? 0;
    }

    get currentPage() {
        return Math.floor(this.offsetValue / this.pageSize) + 1;
    }

    get totalPages() {
        return Math.ceil(this.filteredCasesCount / this.pageSize);
    }

    get isPreviousDisabled() {
        return this.offsetValue === 0;
    }

    get isNextDisabled() {
        return this.filteredCasesCount === 0 ||
            this.offsetValue + this.pageSize >= this.filteredCasesCount;
    }

    handlePrevious() {
        if (this.offsetValue > 0) {
            this.offsetValue = Math.max(
                0,
                this.offsetValue - this.pageSize
            );

            this.updateFilterParams();
        }
    }

    handleNext() {
        if (!this.isNextDisabled) {
            this.offsetValue += this.pageSize;

            this.updateFilterParams();
        }
    }

    updateFilterParams() {
        this.filterParams = {
            priority: this.priorityValue,
            status: this.statusValue,
            pageSize: this.pageSize,
            offsetValue: this.offsetValue
        };
    }

    getSlaStatus(caseRecord) {
        if (caseRecord.SLA_Breached__c === true) {
            return 'Breached';
        }
        
        if (caseRecord.Status === 'Closed') {
            return 'Closed';
        }

        const currentTime = Date.now();
        const twoHoursInMs = 2 * 60 * 60 * 1000;
        const riskDeadline = currentTime + twoHoursInMs;

        const responseDue = caseRecord.SLA_Response_Due__c
            ? new Date(caseRecord.SLA_Response_Due__c).getTime()
            : null;

        const responseAtRisk =
            caseRecord.First_Response_At__c == null &&
            responseDue !== null &&
            responseDue >= currentTime &&
            responseDue <= riskDeadline;

        const resolutionDue = caseRecord.SLA_Resolution_Due__c
            ? new Date(caseRecord.SLA_Resolution_Due__c).getTime()
            : null;

        const resolutionAtRisk =
            resolutionDue !== null &&
            resolutionDue >= currentTime &&
            resolutionDue <= riskDeadline;

        if (responseAtRisk || resolutionAtRisk) {
            return 'At Risk';
        }
        return 'On Track';
    }

    async handleNewCaseButton(event){
        const result = await caseCreateModal.open({
            header : 'New Case'
        });
        if(result === 'success'){
            this.handleRefresh();
        }
    }
}