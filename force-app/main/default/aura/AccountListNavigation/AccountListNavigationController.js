({    
  	invoke : function (component, event, helper) {
   		var navEvent = $A.get("e.force:navigateToList");
   		navEvent.setParams({
          "scope": "Account"
   		});
   		navEvent.fire();
	}
})