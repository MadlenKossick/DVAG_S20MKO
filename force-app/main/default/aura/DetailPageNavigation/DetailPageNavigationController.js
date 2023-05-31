({    
   invoke : function(component, event, helper) {
   		var record = component.get("v.recordId");
   		var redirect = $A.get("e.force:navigateToSObject");
       console.log(record);
   		redirect.setParams({
      		"recordId": record,
           	"slideDevName": "detail"

        });
   		redirect.fire();
	}
})