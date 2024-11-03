global with sharing class CheckOrderDeliveryDateBatch implements Database.Batchable<SObject>{
    global CheckOrderDeliveryDateBatch() {}

    //Faz a pesquisa retornando uma lista de order onde a data de entrega do pedido seja o dia da execução da batch

    global Database.QueryLocator start(Database.BatchableContext BC){
        Date todayDate = Date.today();

        String query = 'SELECT Id, OrderNumber, OrderDelivered__c, Account.Email__c, EmailSent__c FROM Order WHERE DeliveryDate__c =: todayDate';
        System.debug('Query => ' + query);

        return Database.getQueryLocator(query);
    }

    
    global void execute(Database.BatchableContext BC, List<Order> scope){
        
        //Cria uma lista que armazenará os e-mails que vão ser disparados
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();

        //Criando instâncias de custom settins que armazenam paramêtros que serão utilizado para criar e-mails
        OrderEmailNotification__c deliveredOrderSettings = OrderEmailNotification__c.getValues('DeliveredOrder');
        OrderEmailNotification__c undeliveredOrderSettings = OrderEmailNotification__c.getValues('UndeliveredOrder'); 

        //Checa se o pedido foi entregue, gerando um e-mail caso tenha sido entregue ou uma notificação se não tiver sido

        for(Order order : scope){
            if(order.OrderDelivered__c){
                emailMessageList.add(generateEmailMessage(
                    new List<String> {order.Account.Email__c},
                    deliveredOrderSettings.Subject__c + ' - ' + order.OrderNumber,
                    deliveredOrderSettings.Body__c
                    ));               

            }
            else{
                emailMessageList.add(generateEmailMessage(
                    new List<String> {order.Account.Email__c},
                    undeliveredOrderSettings.Subject__c + ' - ' + order.OrderNumber,
                    undeliveredOrderSettings.Body__c
                    ));               
            }
            order.EmailSent__c = true;
        }
        
        Messaging.sendEmail(emailMessageList);
        update scope;
    }

    //Metódo que gera os e-mails
    global Messaging.SingleEmailMessage generateEmailMessage(List<String> toAdress, String subject, String body){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdress);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);

        return mail;
    }

    //Envia uma notificação aos colaboradores da empresa referente ao pedido 
    global void finish (Database.BatchableContext context){
        OrderEmailNotification__c emailNotificationSettings = OrderEmailNotification__c.getValues('EmailNotification');

        Messaging.SingleEmailMessage mail = generateEmailMessage(
                    new List<String> {emailNotificationSettings.ToAddress__c},
                    emailNotificationSettings.Subject__c,
                    emailNotificationSettings.Body__c
                    );   
                    
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
    }
}