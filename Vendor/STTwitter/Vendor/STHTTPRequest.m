//
//  STHTTPRequest.m
//  STHTTPRequest
//
//  Created by Nicolas Seriot on 07.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

//#if __has_feature(objc_arc)
//#else
//// see http://www.codeography.com/2011/10/10/making-arc-and-non-arc-play-nice.html
//#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
//#endif

#import "STHTTPRequest.h"

NSUInteger const kSTHTTPRequestCancellationError = 1;
NSUInteger const kSTHTTPRequestDefaultTimeout = 30;

static NSMutableDictionary *localCredentialsStorage = nil;
static NSMutableArray *localCookiesStorage = nil;

/**/

@interface STHTTPRequestFileUpload : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *parameterName;
@property (nonatomic, strong) NSString *mimeType;

+ (instancetype)fileUploadWithPath:(NSString *)path parameterName:(NSString *)parameterName mimeType:(NSString *)mimeType;
+ (instancetype)fileUploadWithPath:(NSString *)path parameterName:(NSString *)parameterName;
@end

@interface STHTTPRequestDataUpload : NSObject
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *parameterName;
@property (nonatomic, strong) NSString *mimeType; // can be nil
@property (nonatomic, strong) NSString *fileName; // can be nil
+ (instancetype)dataUploadWithData:(NSData *)data parameterName:(NSString *)parameterName mimeType:(NSString *)mimeType fileName:(NSString *)fileName;
@end

/**/

@interface STHTTPRequest ()
@property (nonatomic) NSInteger responseStatus;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *responseStringEncodingName;
@property (nonatomic, strong) NSDictionary *responseHeaders;
@property (nonatomic) NSInteger responseExpectedContentLength; // set by connection:didReceiveResponse: delegate method; web server must send the Content-Length header for accurate value
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableArray *filesToUpload; // STHTTPRequestFileUpload instances
@property (nonatomic, strong) NSMutableArray *dataToUpload; // STHTTPRequestDataUpload instances
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSString *responseString;
@end

@interface NSData (Base64)
- (NSString *)base64Encoding; // private API
@end

@implementation STHTTPRequest

#pragma mark Initializers

+ (STHTTPRequest *)requestWithURL:(NSURL *)url {
    if(url == nil) return nil;
    return [(STHTTPRequest *)[self alloc] initWithURL:url];
}

+ (STHTTPRequest *)requestWithURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    return [self requestWithURL:url];
}

- (STHTTPRequest *)initWithURL:(NSURL *)theURL {
    
    if (self = [super init]) {
        self.url = theURL;
        self.responseData = [[NSMutableData alloc] init];
        self.requestHeaders = [NSMutableDictionary dictionary];
        self.POSTDataEncoding = NSUTF8StringEncoding;
        self.encodePOSTDictionary = YES;
        self.addCredentialsToURL = NO;
        self.timeoutSeconds = kSTHTTPRequestDefaultTimeout;
        self.filesToUpload = [NSMutableArray array];
        self.dataToUpload = [NSMutableArray array];
        // self.HTTPMethod = @"GET"; // default
    }
    
    return self;
}

- (void)clearSession {
    [self deleteAllCookies];
    [[self class] deleteAllCredentials];
}

#pragma mark Credentials

+ (NSMutableDictionary *)sharedCredentialsStorage {
    if(localCredentialsStorage == nil) {
        localCredentialsStorage = [NSMutableDictionary dictionary];
    }
    return localCredentialsStorage;
}

+ (NSURLCredential *)sessionAuthenticationCredentialsForURL:(NSURL *)requestURL {
    return [[[self class] sharedCredentialsStorage] valueForKey:[requestURL host]];
}

+ (void)deleteAllCredentials {
    localCredentialsStorage = [NSMutableDictionary dictionary];
}

- (void)setCredentialForCurrentHost:(NSURLCredential *)c {
#if DEBUG
    NSAssert(_url, @"missing url to set credential");
#endif
    [[[self class] sharedCredentialsStorage] setObject:c forKey:[_url host]];
}

- (NSURLCredential *)credentialForCurrentHost {
    return [[[self class] sharedCredentialsStorage] valueForKey:[_url host]];
}

- (void)setUsername:(NSString *)username password:(NSString *)password {
    NSURLCredential *c = [NSURLCredential credentialWithUser:username
                                                    password:password
                                                 persistence:NSURLCredentialPersistenceNone];
    
    [self setCredentialForCurrentHost:c];
}

- (NSString *)username {
    return [[self credentialForCurrentHost] user];
}

- (NSString *)password {
    return [[self credentialForCurrentHost] password];
}

#pragma mark Cookies

+ (NSMutableArray *)localCookiesStorage {
    if(localCookiesStorage == nil) {
        localCookiesStorage = [NSMutableArray array];
    }
    return localCookiesStorage;
}

- (NSArray *)sessionCookies {
    
    NSArray *allCookies = nil;
    
    if(_ignoreSharedCookiesStorage) {
        allCookies = [[self class] localCookiesStorage];
    } else {
        allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    }
    
    NSArray *sessionCookies = [allCookies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSHTTPCookie *cookie = (NSHTTPCookie *)evaluatedObject;
        return [cookie isSessionOnly];
    }]];
    
    return sessionCookies;
}

- (void)deleteSessionCookies {
    
    for(NSHTTPCookie *cookie in [self sessionCookies]) {
        if(_ignoreSharedCookiesStorage) {
            [[[self class] localCookiesStorage] removeObject:cookie];
        } else {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

- (void)deleteAllCookies {
    if(_ignoreSharedCookiesStorage) {
        [[[self class] localCookiesStorage] removeAllObjects];
    } else {
        NSHTTPCookieStorage *sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [sharedCookieStorage cookies];
        for (NSHTTPCookie *cookie in cookies) {
            [sharedCookieStorage deleteCookie:cookie];
        }
    }
}

- (void)addCookie:(NSHTTPCookie *)cookie {
    
    NSParameterAssert(cookie);
    if(cookie == nil) return;
    
    if(_ignoreSharedCookiesStorage) {
        [[[self class] localCookiesStorage] addObject:cookie];
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        
#if DEBUG
        NSHTTPCookie *readCookie = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] lastObject];
        NSAssert(readCookie, @"cannot read any cookie after adding one");
#endif
    }
}

- (void)addCookieWithName:(NSString *)name value:(NSString *)value url:(NSURL *)url {
    
    NSParameterAssert(url);
    if(url == nil) return;
    
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             name, NSHTTPCookieName,
                                             value, NSHTTPCookieValue,
                                             url, NSHTTPCookieOriginURL,
                                             @"FALSE", NSHTTPCookieDiscard,
                                             @"/", NSHTTPCookiePath,
                                             @"0", NSHTTPCookieVersion,
                                             [[NSDate date] dateByAddingTimeInterval:3600 * 24 * 30], NSHTTPCookieExpires,
                                             nil];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    
    [self addCookie:cookie];
}

- (NSArray *)requestCookies {
    
    if(_ignoreSharedCookiesStorage) {
        NSArray *filteredCookies = [[[self class] localCookiesStorage] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSHTTPCookie *cookie = (NSHTTPCookie *)evaluatedObject;
            return [[cookie domain] isEqualToString:[_url host]];
        }]];
        return filteredCookies;
    } else {
        return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[_url absoluteURL]];
    }
}

- (void)addCookieWithName:(NSString *)name value:(NSString *)value {
    [self addCookieWithName:name value:value url:_url];
}

#pragma mark Headers

- (void)setHeaderWithName:(NSString *)name value:(NSString *)value {
    if(name == nil || value == nil) return;
    [[self requestHeaders] setObject:value forKey:name];
}

- (void)removeHeaderWithName:(NSString *)name {
    if(name == nil) return;
    [[self requestHeaders] removeObjectForKey:name];
}

+ (NSURL *)urlByAddingCredentials:(NSURLCredential *)credentials toURL:(NSURL *)url {
    
    if(credentials == nil) return nil; // no credentials to add
    
    NSString *scheme = [url scheme];
    NSString *host = [url host];
    
    BOOL hostAlreadyContainsCredentials = [host rangeOfString:@"@"].location != NSNotFound;
    if(hostAlreadyContainsCredentials) return url;
    
    NSMutableString *resourceSpecifier = [[url resourceSpecifier] mutableCopy];
    
    if([resourceSpecifier hasPrefix:@"//"] == NO) return nil;
    
    NSString *userPassword = [NSString stringWithFormat:@"%@:%@@", credentials.user, credentials.password];
    
    [resourceSpecifier insertString:userPassword atIndex:2];
    
    NSString *urlString = [NSString stringWithFormat:@"%@:%@", scheme, resourceSpecifier];
    
    return [NSURL URLWithString:urlString];
}

// {k2:v2, k1:v1} -> [{k1:v1}, {k2:v2}]
+ (NSArray *)dictionariesSortedByKey:(NSDictionary *)dictionary {
    NSMutableArray *sortedDictionaries = [NSMutableArray arrayWithCapacity:[dictionary count]];
    NSArray *sortedKeys = [dictionary keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    for(NSString *key in sortedKeys) {
        NSDictionary *d = @{ key : dictionary[key] };
        [sortedDictionaries addObject:d];
    }
    return sortedDictionaries;
}

+ (NSData *)multipartContentWithBoundary:(NSString *)boundary data:(NSData *)someData fileName:(NSString *)fileName parameterName:(NSString *)parameterName mimeType:(NSString *)aMimeType {
    
    NSString *mimeType = aMimeType ? aMimeType : @"application/octet-stream";
    
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *fileNameContentDisposition = fileName ? [NSString stringWithFormat:@"filename=\"%@\"", fileName] : @"";
    NSString *contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; %@\r\n", parameterName, fileNameContentDisposition];
    
    [data appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:someData];
    [data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return data;
}

- (NSMutableURLRequest *)requestByAddingCredentialsToURL:(BOOL)useCredentialsInURL {
    
    NSURL *theURL = nil;
    
    if(useCredentialsInURL) {
        NSURLCredential *credential = [self credentialForCurrentHost];
        if(credential == nil) return nil;
        theURL = [[self class] urlByAddingCredentials:credential toURL:_url];
        if(theURL == nil) return nil;
    } else {
        theURL = _url;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:theURL];
    [request setHTTPMethod:_HTTPMethod];
    
    request.timeoutInterval = self.timeoutSeconds;
    
    if(_ignoreSharedCookiesStorage) {
        NSArray *cookies = [self sessionCookies];
        NSDictionary *d = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        [request setAllHTTPHeaderFields:d];
    }
    
    // escape POST dictionary keys and values if needed
    if(_encodePOSTDictionary) {
        NSMutableDictionary *escapedPOSTDictionary = _POSTDictionary ? [NSMutableDictionary dictionary] : nil;
        [_POSTDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *k = [key st_stringByAddingRFC3986PercentEscapesUsingEncoding:_POSTDataEncoding];
            NSString *v = [[obj description] st_stringByAddingRFC3986PercentEscapesUsingEncoding:_POSTDataEncoding];
            [escapedPOSTDictionary setValue:v forKey:k];
        }];
        self.POSTDictionary = escapedPOSTDictionary;
    }
    
    // sort POST parameters in order to get deterministic, unit testable requests
    NSArray *sortedPOSTDictionaries = [[self class] dictionariesSortedByKey:_POSTDictionary];
    
    if([self.filesToUpload count] > 0 || [self.dataToUpload count] > 0) {
        
        NSString *boundary = @"----------kStHtTpReQuEsTbOuNdArY";
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        /**/
        
        for(STHTTPRequestFileUpload *fileToUpload in self.filesToUpload) {
            
            NSData *data = [NSData dataWithContentsOfFile:fileToUpload.path];
            if(data == nil) continue;
            NSString *fileName = [fileToUpload.path lastPathComponent];
            
            NSData *multipartData = [[self class] multipartContentWithBoundary:boundary
                                                                          data:data
                                                                      fileName:fileName
                                                                 parameterName:fileToUpload.parameterName
                                                                      mimeType:fileToUpload.mimeType];
            [body appendData:multipartData];
        }
        
        /**/
        
        for(STHTTPRequestDataUpload *dataToUpload in self.dataToUpload) {
            NSData *multipartData = [[self class] multipartContentWithBoundary:boundary
                                                                          data:dataToUpload.data
                                                                      fileName:dataToUpload.fileName
                                                                 parameterName:dataToUpload.parameterName
                                                                      mimeType:dataToUpload.mimeType];
            
            [body appendData:multipartData];
        }
        
        /**/
        
        [sortedPOSTDictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *d = (NSDictionary *)obj;
            NSString *key = [[d allKeys] lastObject];
            NSObject *value = [[d allValues] lastObject];
            
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[value description] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
        
        /**/
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if([request HTTPMethod] == nil) [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", (unsigned int)[body length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:body];
        
    } else if (_rawPOSTData) {
        
        if([request HTTPMethod] == nil) [request setHTTPMethod:@"POST"];
        
        [request setValue:[NSString stringWithFormat:@"%u", (unsigned int)[_rawPOSTData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:_rawPOSTData];
        
    } else if (_POSTDictionary != nil) { // may be empty (POST request without body)
        
        if(_encodePOSTDictionary) {
            
            CFStringEncoding cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(_POSTDataEncoding);
            NSString *encodingName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfStringEncoding);
            
            if(encodingName) {
                NSString *contentTypeValue = [NSString stringWithFormat:@"application/x-www-form-urlencoded ; charset=%@", encodingName];
                [self setHeaderWithName:@"Content-Type" value:contentTypeValue];
            }
        }
        
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:[_POSTDictionary count]];
        
        [sortedPOSTDictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *d = (NSDictionary *)obj;
            NSString *key = [[d allKeys] lastObject];
            NSObject *value = [[d allValues] lastObject];
            
            NSString *kv = [NSString stringWithFormat:@"%@=%@", key, value];
            [ma addObject:kv];
        }];
        
        NSString *s = [ma componentsJoinedByString:@"&"];
        
        NSData *data = [s dataUsingEncoding:_POSTDataEncoding allowLossyConversion:YES];
        
        if([request HTTPMethod] == nil) [request setHTTPMethod:@"POST"];
        
        [request setValue:[NSString stringWithFormat:@"%u", (unsigned int)[data length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:data];
    } else {
        if([request HTTPMethod] == nil) [request setHTTPMethod:@"GET"];
    }
    
    [_requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request addValue:obj forHTTPHeaderField:key];
    }];
    
    NSURLCredential *credentialForHost = [self credentialForCurrentHost];
    
    if(credentialForHost) {
        NSString *authString = [NSString stringWithFormat:@"%@:%@", credentialForHost.user, credentialForHost.password];
        NSData *authData = [authString dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
        [request addValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}

- (NSURLRequest *)requestByAddingCredentialsToURL {
    return [self requestByAddingCredentialsToURL:YES];
}

#pragma mark Upload

- (void)addFileToUpload:(NSString *)path parameterName:(NSString *)parameterName {
    
    STHTTPRequestFileUpload *fu = [STHTTPRequestFileUpload fileUploadWithPath:path parameterName:parameterName];
    [self.filesToUpload addObject:fu];
}

- (void)addDataToUpload:(NSData *)data parameterName:(NSString *)param {
    STHTTPRequestDataUpload *du = [STHTTPRequestDataUpload dataUploadWithData:data parameterName:param mimeType:nil fileName:nil];
    [self.dataToUpload addObject:du];
}

- (void)addDataToUpload:(NSData *)data parameterName:(NSString *)param mimeType:(NSString *)mimeType fileName:(NSString *)fileName {
    STHTTPRequestDataUpload *du = [STHTTPRequestDataUpload dataUploadWithData:data parameterName:param mimeType:mimeType fileName:fileName];
    [self.dataToUpload addObject:du];
}

#pragma mark Response

- (NSString *)stringWithData:(NSData *)data encodingName:(NSString *)encodingName {
    if(data == nil) return nil;
    
    if(_forcedResponseEncoding > 0) {
        return [[NSString alloc] initWithData:data encoding:_forcedResponseEncoding];
    }
    
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    /* try to use encoding declared in HTTP response headers */
    
    if(encodingName != nil) {
        
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
        
        if(encoding == kCFStringEncodingInvalidId) {
            encoding = NSUTF8StringEncoding; // by default
        }
    }
    
    return [[NSString alloc] initWithData:data encoding:encoding];
}

- (NSString *)curlDescription {
    
    NSMutableArray *ma = [NSMutableArray array];
    [ma addObject:@"$ curl -i"];
    
    // -u usernane:password
    
    NSURLCredential *credential = [[self class] sessionAuthenticationCredentialsForURL:[self url]];
    if(credential) {
        NSString *s = [NSString stringWithFormat:@"-u \"%@:%@\"", credential.user, credential.password];
        [ma addObject:s];
    }
    
    // -d "k1=v1&k2=v2"                                             // POST, url encoded params
    
    if(_POSTDictionary) {
        NSMutableArray *postParameters = [NSMutableArray array];
        [_POSTDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *s = [NSString stringWithFormat:@"%@=%@", key, obj];
            [postParameters addObject:s];
        }];
        NSString *ss = [postParameters componentsJoinedByString:@"&"];
        [ma addObject:[NSString stringWithFormat:@"-d \"%@\"", ss]];
    }
    
    // -F "coolfiles=@fil1.gif;type=image/gif,fil2.txt,fil3.html"   // file upload
    
    for(STHTTPRequestFileUpload *f in _filesToUpload) {
        NSString *s = [NSString stringWithFormat:@"%@=@%@", f.parameterName, f.path];
        [ma addObject:[NSString stringWithFormat:@"-F \"%@\"", s]];
    }
    
    // -b "name=Daniel;age=35"                                      // cookies
    
    NSArray *cookies = [self requestCookies];
    
    NSMutableArray *cookiesStrings = [NSMutableArray array];
    for(NSHTTPCookie *cookie in cookies) {
        NSString *s = [NSString stringWithFormat:@"%@=%@", [cookie name], [cookie value]];
        [cookiesStrings addObject:s];
    }
    
    if([cookiesStrings count] > 0) {
        [ma addObject:[NSString stringWithFormat:@"-b \"%@\"", [cookiesStrings componentsJoinedByString:@";"]]];
    }
    
    // -H "X-you-and-me: yes"                                       // extra headers
    
    NSMutableDictionary *headers = [[_request allHTTPHeaderFields] mutableCopy];
    [headers removeObjectForKey:@"Cookie"];

    NSMutableArray *headersStrings = [NSMutableArray array];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *s = [NSString stringWithFormat:@"-H \"%@: %@\"", key, obj];
        [headersStrings addObject:s];
    }];
    
    if([headersStrings count] > 0) {
        [ma addObject:[headersStrings componentsJoinedByString:@" \\\n"]];
    }
    
    // url
    
    [ma addObject:[NSString stringWithFormat:@"\"%@\"", _url]];
    
    return [ma componentsJoinedByString:@" \\\n"];
}

- (NSString *)debugDescription {
    
    NSMutableString *ms = [NSMutableString string];
    
    NSString *method = (self.POSTDictionary || [self.filesToUpload count] || [self.dataToUpload count]) ? @"POST" : @"GET";
    
    [ms appendFormat:@"%@ %@\n", method, [_request URL]];
    
    NSMutableDictionary *headers = [[_request allHTTPHeaderFields] mutableCopy];
    [headers removeObjectForKey:@"Cookie"];
    
    if([headers count]) [ms appendString:@"HEADERS\n"];
    
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [ms appendFormat:@"\t %@ = %@\n", key, obj];
    }];
    
    NSArray *cookies = [self requestCookies];
    
    if([cookies count]) [ms appendString:@"COOKIES\n"];
    
    for(NSHTTPCookie *cookie in cookies) {
        [ms appendFormat:@"\t %@ = %@\n", [cookie name], [cookie value]];
    }
    
    NSArray *kvDictionaries = [[self class] dictionariesSortedByKey:_POSTDictionary];
    
    if([kvDictionaries count]) [ms appendString:@"POST DATA\n"];
    
    for(NSDictionary *kv in kvDictionaries) {
        NSString *k = [[kv allKeys] lastObject];
        NSString *v = [[kv allValues] lastObject];
        [ms appendFormat:@"\t %@ = %@\n", k, v];
    }
    
    for(STHTTPRequestFileUpload *f in self.filesToUpload) {
        [ms appendString:@"UPLOAD FILE\n"];
        [ms appendFormat:@"\t %@ = %@\n", f.parameterName, f.path];
    }
    
    for(STHTTPRequestDataUpload *d in self.dataToUpload) {
        [ms appendString:@"UPLOAD DATA\n"];
        [ms appendFormat:@"\t %@ = [%u bytes]\n", d.parameterName, (unsigned int)[d.data length]];
    }
    
    return ms;
}

#pragma mark Start Request

- (void)startAsynchronous {
    
    NSMutableURLRequest *request = [self requestByAddingCredentialsToURL:_addCredentialsToURL];
    
    [request setHTTPShouldHandleCookies:(_ignoreSharedCookiesStorage == NO)];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    
    self.request = [_connection currentRequest];
    
    self.requestHeaders = [[_request allHTTPHeaderFields] mutableCopy];
        
    /**/
    
    BOOL showDebugDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"STHTTPRequestShowDebugDescription"];
    BOOL showCurlDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"STHTTPRequestShowCurlDescription"];
    
    NSMutableString *logString = nil;
    
    if(showDebugDescription || showCurlDescription) {
        logString = [NSMutableString stringWithString:@"\n----------\n"];
    }
    
    if(showDebugDescription) {
        [logString appendString:[self debugDescription]];
    }
    
    if(showDebugDescription && showCurlDescription) {
        [logString appendString:@"\n"];
    }
    
    if(showCurlDescription) {
        [logString appendString:[self curlDescription]];
    }
    
    if(showDebugDescription || showCurlDescription) {
        [logString appendString:@"\n----------\n"];
    }
    
    if(logString) NSLog(@"%@", logString);
    
    /**/
    
    if(_connection == nil) {
        NSString *s = @"can't create connection";
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:0
                                     userInfo:userInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _errorBlock(_error);
        });
    }
}

- (NSString *)startSynchronousWithError:(NSError **)e {
    
    self.responseHeaders = nil;
    self.responseStatus = 0;
    
    NSURLRequest *request = [self requestByAddingCredentialsToURL:_addCredentialsToURL];
    
    NSURLResponse *urlResponse = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:e];
    if(data == nil) return nil;
    
    self.responseData = [NSMutableData dataWithData:data];
    
    if([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)urlResponse;
        
        self.responseHeaders = [httpResponse allHeaderFields];
        self.responseStatus = [httpResponse statusCode];
        self.responseStringEncodingName = [httpResponse textEncodingName];
    }
    
    self.responseString = [self stringWithData:_responseData encodingName:_responseStringEncodingName];
    
    if(_responseStatus >= 400) {
        if(e) *e = [NSError errorWithDomain:NSStringFromClass([self class]) code:_responseStatus userInfo:nil];
    }
    
    return _responseString;
}

- (void)cancel {
    [_connection cancel];
    
    NSString *s = @"Connection was cancelled.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey];
    self.error = [NSError errorWithDomain:NSStringFromClass([self class])
                                     code:kSTHTTPRequestCancellationError
                                 userInfo:userInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _errorBlock(_error);
    });
}

#pragma mark NSURLConnectionDelegate

-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    //return YES to say that we have the necessary credentials to access the requested resource
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    
    // Server Trust authentication
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *serverTrustCredential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:serverTrustCredential forAuthenticationChallenge:challenge];
        return;
    }
    
    // Digest and Basic authentication
    else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest] ||
             [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
        
        if([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [self credentialForCurrentHost];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            [[[self class] sharedCredentialsStorage] removeObjectForKey:[_url host]];
            [connection cancel];
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
    
    // Unhandled
    else
    {
        NSLog(@"Unhandled authentication challenge type - %@", authenticationMethod);
        [connection cancel];
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
    
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (_uploadProgressBlock) {
        _uploadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    if([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
        self.responseHeaders = [r allHeaderFields];
        self.responseStatus = [r statusCode];
        self.responseStringEncodingName = [r textEncodingName];
        self.responseExpectedContentLength = [r expectedContentLength];
    }
    
    [_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
    
    [_responseData appendData:theData];
    
    if (_downloadProgressBlock) {
        _downloadProgressBlock(theData, [_responseData length], self.responseExpectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.responseString = [self stringWithData:_responseData encodingName:_responseStringEncodingName];
    
    if(_responseStatus >= 400) {
        self.error = [NSError errorWithDomain:NSStringFromClass([self class]) code:_responseStatus userInfo:nil];
        _errorBlock(_error);
        return;
    }
    
    _completionBlock(_responseHeaders, [self responseString]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
    self.error = e;
    _errorBlock(_error);
}

@end

/**/

@implementation NSError (STHTTPRequest)

- (BOOL)st_isAuthenticationError {
    if([[self domain] isEqualToString:NSURLErrorDomain] == NO) return NO;
    
    return ([self code] == kCFURLErrorUserCancelledAuthentication || [self code] == kCFURLErrorUserAuthenticationRequired);
}

- (BOOL)st_isCancellationError {
    if([[self domain] isEqualToString:@"STHTTPRequest"] == NO) return NO;
    
    return ([self code] == kSTHTTPRequestCancellationError);
}

@end

@implementation NSString (RFC3986)
- (NSString *)st_stringByAddingRFC3986PercentEscapesUsingEncoding:(NSStringEncoding)encoding {
    
    NSString *s = (__bridge_transfer NSString *)(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                         (CFStringRef)self,
                                                                                         NULL,
                                                                                         CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                         kCFStringEncodingUTF8));
    return s;
}
@end

/**/

#if DEBUG
@implementation NSURLRequest (IgnoreSSLValidation)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return NO;
}

@end
#endif

/**/

@implementation STHTTPRequestFileUpload

+ (instancetype)fileUploadWithPath:(NSString *)path parameterName:(NSString *)parameterName mimeType:(NSString *)mimeType {
    STHTTPRequestFileUpload *fu = [[self alloc] init];
    fu.path = path;
    fu.parameterName = parameterName;
    fu.mimeType = mimeType;
    return fu;
}

+ (instancetype)fileUploadWithPath:(NSString *)path parameterName:(NSString *)fileName {
    return [self fileUploadWithPath:path parameterName:fileName mimeType:@"application/octet-stream"];
}

@end

@implementation STHTTPRequestDataUpload

+ (instancetype)dataUploadWithData:(NSData *)data parameterName:(NSString *)parameterName mimeType:(NSString *)mimeType fileName:(NSString *)fileName {
    STHTTPRequestDataUpload *du = [[self alloc] init];
    du.data = data;
    du.parameterName = parameterName;
    du.mimeType = mimeType;
    du.fileName = fileName;
    return du;
}

@end
