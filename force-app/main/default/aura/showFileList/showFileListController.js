({
    doInit : function(component, event, helper) {
        

        // Prepare the action to load account record
        var action = component.get("c.getRelatedFilesByRecordId");
        action.setParams({"recordId": component.get("v.recordId")});

        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var data = response.getReturnValue();
                
                console.log(data)
                var filesList = Object.keys(data).map(item=>({"label":data[item],
                "value": item,
                "url":`/sfc/servlet.shepherd/document/download/${item}`,
                "url_preview":`/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&amp;versionId=${item}`
                }));                
                component.set("v.fileList", filesList);

                if (filesList.length > 0) {
                    component.set("v.b_showFileList", true);
                }
            } else {
                console.log('Problem getting account, response state: ' + state);
            }
        });
        $A.enqueueAction(action);
    },
    previewFile :function(component,event,helper){  
        var rec_id = event.currentTarget.id;  
        console.log(rec_id);
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [rec_id]
        });  
    },
})