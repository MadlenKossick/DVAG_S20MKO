({
   	doInit: function(component, event, helper){
        //alert(component.get('v.testAttr'));
        const flow = component.find("startFlow");
        var accountId = component.get("v.parentFieldId");
        console.log('parentFieldId >>' , accountId);
        var inputVariables = [
          {name: "recordId", type: "String", value: accountId },
          {name: "pvar_b_IsFinancialAccount", type: "Boolean", value: true }
       	];
        console.log('inputVariables', inputVariables);
        flow.startFlow("CreateInsurancePolicyorFinancialAccount",inputVariables);
    },
    
   closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
   },
   
    handleStatusChange: function (component, event) {
    	if(event.getParam("status") === "FINISHED") {
        	// Refresh the Account Page after Flow finishes
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
            	"recordId": component.get("v.parentFieldId"),
                "isredirect": "true"
             });
             urlEvent.fire();
          }
	}  
})