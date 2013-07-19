/*
DATWENDO 7/2013
CS
BSD 2 License 
*/
Public Class Connector
{
    static final String ServiceUrl                  ='http://datwendosvc.cloudapp.net/api/v1';
    public static final String GENERIC_ERR          = 'AN ERROR HAS OCCURRED. ';   
    public static final String CCtorAPIController   = 'CCtor';
    public Boolean isApiError                       = false;

    public long CounterId                           = 0;
    public long PublisherId                         = 0;
    public Boolean IsFast                           = true;
    public String SecretKey;
    public long Delay                               = 200;    
    public String NewTransacKey                     = '';
    public long  newVal                             = 0;

    public String Fieldname                         = '';
    public ID newObjectID;

    Public Class CCtrRequest2
    {
        String Ky { get; set;}
        long Dl { get; set;}
    }

        Public Class PubCCtrRequest
    {
        String Ky { get; set;}
        long Pb { get; set;}
    }

            Public Class CCtrResponse
    {
        public long Cd { get; set; }
        public long Vl { get; set; }
    }

                Public Class CCtrResponse2
    {
        public long Cd { get; set; }
        public long Pr { get; set; }
        public string Ky { get; set; }
    }

    public Connector(ID obID, String fName,long publisherId, long cId, String secret,Boolean fast, long delay)
    {
        newObjectID     = obID;
        Fieldname       = fName;
        CounterId       = cId;
        SecretKey       = secret;
        NewTransacKey   = secret;
        IsFast          = fast;
        Delay           = delay;
        PublisherId     = publisherId;
    }


    @future (callout=true)
    public static void ReadNextIndex(ID obID, String fName,long publisherId, long cId, String secret,Boolean fast, long delay)
    {
        Connector connector = new Connector(obID,fName,publisherId,cId,secret,fast, delay);
        connector.ReadNext();
    }

    private void SetIndex()
    {
        // Get the sObject token from the  ID
        Schema.SObjectType token = newObjectID.getSObjectType();

        // Using the token, do a describe 
        // and construct a query dynamically. 
        Schema.DescribeSObjectResult dr = token.getDescribe();
        String queryString = 'SELECT '+Fieldname+' FROM ' + dr.getName() + ' WHERE Id=\'' + newObjectID + '\'';
        sObject[] objDBList = Database.query(queryString);
        if (objDBList.size() != 1 )
            return;
        objDBList[0].put(Fieldname,String.valueOf(newVal));
        Database.update(objDBList, false);
    }

    // Extract a new transaction key from server
    public void TransacKey()
    {
        CCtrRequest2 CParam                             = new CCtrRequest2();
        CParam.Ky                                       = SecretKey;
        CParam.Dl                                       = Delay;


        try
        {
            String str                          = Post4TransacSync(CParam);
            CCtrResponse2 CRep                  = (CCtrResponse2)JSON.deserialize(str, CCtrResponse2.class);
            if (CRep.Cd == 0)
            {
                NewTransacKey                          = CRep.Ky;
            }
        }
        catch(Exception ex)
        {
            System.Debug('Exception in TransacKey');
        }
    }

    private String Post4TransacSync(CCtrRequest2 CReq)
    {
        String result                           = '';
        if ( !Test.isRunningTest())
        {

            String[] Params                     = new String[] {ServiceUrl, CCtorAPIController, String.valueOf(CounterId)};
            String url                          = String.Format('{0}/{1}/{2}', Params);

            // Instantiate a new http object
            Http h                              = new Http();
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req                     = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json'); 
            String JSONString                   = JSON.serialize(CReq);  
            req.setBody(JSONString);
            // Send the request, and return a response
            HttpResponse response               = h.send(req);
            result                              = response.getBody();
            String errorChkMsg                  = checkForError(result);
            isApiError                          = false;
            if(errorChkMsg != '')
            {
              result                            = errorChkMsg;
              isApiError                        = true;
            } 
        }
        else // if(Test.isRunningTest())
        {
            isApiError                              = false;
        }
        return result;
    }

    public void ReadNext()
    {
        if (!IsFast )
                TransacKey();

        PubCCtrRequest CReq                     = new PubCCtrRequest();
        CReq.Ky                                 = NewTransacKey;
        CReq.Pb                                 = PublisherId;

        try
        {
            String str                          = PutSync(CReq);

            CCtrResponse CRep                   = (CCtrResponse)JSON.deserialize(str, CCtrResponse.class);
            if (CRep.Cd == 0)
            {
                newVal                          = CRep.Vl;
                //install new index value
                SetIndex();
            }
        }
        catch(Exception ex)
        {
            System.Debug('Exception in ReadNext');
        }
    }

    private String PutSync(PubCCtrRequest CReq)
    {           
        String result                           = '';
        if ( !Test.isRunningTest())
        {
            String[] Params                     = new String[] {ServiceUrl, CCtorAPIController, String.valueOf(CounterId)};
            String url                          = String.Format('{0}/{1}/{2}', Params);

            // Instantiate a new http object
            Http h                              = new Http();
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req                     = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json'); 
            String JSONString                   = JSON.serialize(Creq);    
            req.setBody(JSONString);
            // Send the request, and return a response
            HttpResponse response               = h.send(req);
            result                              = response.getBody();
            String errorChkMsg                  = checkForError(result);
            isApiError                          = false;
            if(errorChkMsg != '')
            {
              result                            = errorChkMsg;
              isApiError                        = true;
            }        
        }
        else 
        {
            isApiError                          = false;
        }
        return result;
    }

    private static  String checkForError(String jsonString)
    {
        JSONParser parser       = JSON.createParser(jsonString);
        Boolean isError         = false;
        String result           = GENERIC_ERR;
        String reason, message;
        while (parser.nextToken() != null) 
        {
            if(parser.getCurrentToken() == JSONToken.START_OBJECT && !isError)
            {
                parser.nextToken();
                if(parser.getText() == 'error'){ //if first element in the json string is 'error'
                  isError = true;          
                }
              }      
            else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME && isError))
            { //if the response is truly an error
                String fieldName = parser.getText();
                parser.nextToken();
                  if(fieldName == 'reason') {
                  reason = parser.getText();
                   }
                   else if(fieldName == 'message'){
                     message = parser.getText();
                   }
            }
        }
        if(reason != null && message != null)
          result += reason + ': ' + message;
        else
          result = '';

        return result;  
      }
}

