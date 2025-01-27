public class SYS_IntegrationLogInboundImmediate{ 
    
    private List<Id> sysLogIds = new List<Id>();
    
    public SYS_IntegrationLogInboundImmediate(List<Id> idList){
        this.sysLogIds = idList;
    }

    public void execute(){
        
        List<sObject> inboundResultLogs = new List<sObject>();
    
        List<SYS_IntegrationLog__c> sysLogs = 
                                            [SELECT 
                                                id,
                                                data0__c,
                                                data1__c,
                                                data2__c,
                                                data3__c,
                                                data4__c,
                                                data5__c,
                                                data6__c,
                                                data7__c,
                                                data8__c,
                                                data9__c,
                                                External_Id_Field_API_Name__c,
                                                How_to_process__c,Custom_Apex_Handler__c,SYS_Operation_Type__c,Flat_Key_for_Resource__c,
                                                Type__c,WhatId__c,Parent__c,Order__c,ObjectSettingId__c,SYS_IntegrationSettings__c
                                            FROM SYS_IntegrationLog__c 
                                            WHERE Id in:sysLogIds];
        
        for(SYS_IntegrationLog__c log:sysLogs) {
            
            try{
                SYS_DataCache.INT_TYPE = log.SYS_IntegrationSettings__c;
                // NA SYS_DataCache.OBJ_TYPE = log.ObjectSettingId__c;
                SYS_ApplicationService appService;

                System.debug('How to process:'+log.How_to_process__c);
                System.debug('SYS_DataCache.OBJ_TYPE:'+SYS_DataCache.OBJ_TYPE);
                
                if(log.How_to_process__c == 'use_object_setting')
                    appService = (SYS_ApplicationService)Type.forName(SYS_DataCache.objectSettingMap.get(SYS_DataCache.OBJ_TYPE).ApexHandler__c).newInstance();
                else if(log.How_to_process__c == 'use_custom_apex_handler')
                    appService = (SYS_ApplicationService)Type.forName(log.Custom_Apex_Handler__c).newInstance();
                else if(log.How_to_process__c == 'ignore_log'){
                    continue;
                }
                else{
                    //Log Message
                    continue;
                }

                Boolean dmlResult = appService.doInbound(log);
                
                inboundResultLogs.add(appService.generatelogForInboundResult(dmlResult,log));
            }catch(Exception e){
                SYS_ApplicationService.logException(log, e.getStackTraceString());
            }

        }// For loop ends

        if(inboundResultLogs.size()>0){
            new SYS_ApplicationService().doDML(inboundResultLogs,'UPSERT','');  
        }

    
    }
}