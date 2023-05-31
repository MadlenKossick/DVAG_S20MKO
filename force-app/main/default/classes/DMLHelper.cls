/**
 * @author Jochen Litzinger, Cloud Consulting Group
 * @date 2023
 *
 * @group Batchable
 *
 * @description Helper class for Database insert, update & delete results
 * 
 */

 public without sharing class DMLHelper implements Iterable<DmlResult> {
    public class DmlResult {
    	public Id recordId;
    	public Integer rowIndex;
    	public Boolean success;
    	public Database.Error[] errors;

    	public DmlResult(Boolean success, Id recordId, Database.Error[] errors, Integer rowIndex) {
    		this.success = success;
    		this.recordId = recordId;
    		this.errors = errors;
    		this.rowIndex = rowIndex;
    	}
    }

    public DmlResult[] dmlResults;
    	
    public DMLHelper(Database.SaveResult[] results) {
        dmlResults = new DmlResult[0];
        Integer index = 0;
        for(Database.SaveResult result : results) {
            if (!result.isSuccess()) {
               // System.debug('inside unsucessfull records failed result-->' + results);
               // System.debug('result.getErrors()-->' + result.getErrors());
               dmlResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), index));
            }
            index++;
        }
    }

    public DMLHelper(Database.upsertResult[] results) {
        dmlResults = new DmlResult[0];
        Integer index = 0;
        for(Database.upsertResult result : results) {
            if (!result.isSuccess()) {
                dmlResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), index));
            }  
            index++;
        }
        system.debug('dmlResults upsert contact-->'+dmlResults);
    }

    public DMLHelper(Database.DeleteResult[] results) {
        dmlResults = new DmlResult[0];
        Integer index = 0;
        for(Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                dmlResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), index));
            }
            index++;
        }
    }

    /* UNCOMMENT IF NEEDED
    public DMLHelper(Database.UndeleteResult[] results) {
        dmlResults = new DmlResult[0];
        Integer index = 0;
        for(Database.UndeleteResult result : results) {
            if (!result.isSuccess()) {
                dmlResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), index++));
            }
        }
    }
    */

    public Iterator<DmlResult> iterator() {
        return dmlResults.iterator();
    }
}