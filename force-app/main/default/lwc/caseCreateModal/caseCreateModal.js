import LightningModal from 'lightning/modal';
import { api } from 'lwc';
import CASE_OBJ from '@salesforce/schema/Case';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseCreateModal extends LightningModal {
    @api header = 'Test Value';
    caseObject = CASE_OBJ;
    isDisabled = false;

    handleClose(){
        this.close();
    }

    handleSubmit(){
        this.isDisabled = true;
    }

    handleSuccess(event){        
        this.handleEventHelper('Success' , 'Case Created Successfully with id '+event.detail.id , 'success');
        this.close('success');
    }

    handleError(){
        this.isDisabled = false;
        this.handleEventHelper('Error' , 'Unable to create Case.' , 'error');
    }

    handleEventHelper(title , message , variant){
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }))
    }    
}