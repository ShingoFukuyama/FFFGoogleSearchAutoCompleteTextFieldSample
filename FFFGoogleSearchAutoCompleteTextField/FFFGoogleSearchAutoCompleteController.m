//
//  FFFGoogleSearchAutoCompleteController.m
//  FFFGoogleSearchAutoCompleteTextField
//
//  Created by FukuyamaShingo on 7/17/14.
//  Copyright (c) 2014 ShingoFukuyama. All rights reserved.
//

#import "FFFGoogleSearchAutoCompleteController.h"
#import "FFFGoogleSearchAutoCompleteTextField.h"
#import <AFNetworking.h>

typedef NS_ENUM (NSUInteger, FFFAutoSuggestionAPI) {
    FFFAutoSuggestionAPIGoogle,
    FFFAutoSuggestionAPIDuckDuckGo
};

@interface FFFGoogleSearchAutoCompleteController ()
<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NSXMLParserDelegate>
@property (nonatomic, strong) FFFGoogleSearchAutoCompleteTextField  *searchTextField;
@property (nonatomic, strong) NSString                *lastStringInSearchTextField;
@property (nonatomic, strong) UITableView             *suggestionTable;
@property (nonatomic, strong) NSMutableArray          *suggestions;
@property (nonatomic, assign) FFFAutoSuggestionAPI    APIType;
@property (nonatomic, strong) UIButton                *googleButton;
@property (nonatomic, strong) UIButton                *duckDuckGoButton;
@end

@implementation FFFGoogleSearchAutoCompleteController

static NSString *FFFTableViewCellIdentifier = @"FFFTableViewCellIdentifier";

- (void)viewDidLoad
{
    [super viewDidLoad];

    _suggestions = [NSMutableArray array];
    _APIType = FFFAutoSuggestionAPIGoogle;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(KeyboardDidChangeFrame:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];

    _searchTextField = [[FFFGoogleSearchAutoCompleteTextField alloc] initWithFrame:CGRectMake(10.0, self.view.frame.size.height - 90.0, self.view.frame.size.width - 20.0, 32.0)];
    _searchTextField.delegate = self;
    [_searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:_searchTextField];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:[NSBlockOperation blockOperationWithBlock:^{
        [_searchTextField becomeFirstResponder];
    }] selector:@selector(main) userInfo:nil repeats:NO];
    

    
    _googleButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-50.0-75.0,
                                                               self.view.frame.size.height/4.5,
                                                               100.0,
                                                               100.0)];
    [_googleButton setImage:[UIImage imageNamed:@"google.png"] forState:UIControlStateNormal];
    _googleButton.layer.cornerRadius = 50.0;
    [self.view insertSubview:_googleButton atIndex:0];
    [_googleButton addTarget:self action:@selector(switchAPIToGoogle:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _duckDuckGoButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-50.0+75.0,
                                                                   self.view.frame.size.height/4.5,
                                                                   100.0,
                                                                   100.0)];
    [_duckDuckGoButton setImage:[UIImage imageNamed:@"duckduckgo.png"] forState:UIControlStateNormal];
    _duckDuckGoButton.layer.cornerRadius = 50.0;
    [self.view insertSubview:_duckDuckGoButton atIndex:0];
    [_duckDuckGoButton addTarget:self action:@selector(switchAPIToDuckDuckGo:) forControlEvents:UIControlEventTouchUpInside];
    
    if (_APIType == FFFAutoSuggestionAPIGoogle) {
        _duckDuckGoButton.alpha = 0.2;
    } else {
        _duckDuckGoButton.alpha = 0.2;
    }
}
- (void)switchAPIToGoogle:(UIButton *)button
{
    if (_APIType != FFFAutoSuggestionAPIGoogle) {
        _APIType = FFFAutoSuggestionAPIGoogle;
        [UIView animateWithDuration:0.4 animations:^{ button.alpha = 1.0; }];
        [UIView animateWithDuration:0.4 animations:^{ _duckDuckGoButton.alpha = 0.2; }];
    }
}
- (void)switchAPIToDuckDuckGo:(UIButton *)button
{
    if (_APIType != FFFAutoSuggestionAPIDuckDuckGo) {
        _APIType = FFFAutoSuggestionAPIDuckDuckGo;
        [UIView animateWithDuration:0.4 animations:^{ button.alpha = 1.0; }];
        [UIView animateWithDuration:0.4 animations:^{ _googleButton.alpha = 0.2; }];
    }
}
- (void)showSuggestionTable
{
    _suggestionTable = [[UITableView alloc] initWithFrame:
                        CGRectMake(0,
                                   20.0,
                                   self.view.frame.size.width,
                                   300.0) style:UITableViewStylePlain];
    [_suggestionTable registerClass:[UITableViewCell class] forCellReuseIdentifier:FFFTableViewCellIdentifier];
    _suggestionTable.delegate   = self;
    _suggestionTable.dataSource = self;
    [self.view insertSubview:_suggestionTable belowSubview:_searchTextField];
}
- (void)hideSuggestionTable
{
    _suggestions = [NSMutableArray array];
    [_suggestionTable removeFromSuperview];
}
- (void)changeSuggestionTableFrame
{
    _suggestionTable.frame = CGRectMake(0, 20.0, _suggestionTable.frame.size.width, _searchTextField.frame.origin.y - 28.0);
}
- (void)refreshSuggestionTable
{
    _suggestions = [[[_suggestions reverseObjectEnumerator] allObjects] mutableCopy];
    [_suggestionTable reloadData];
    NSInteger indexForEndOfSuggestion = _suggestions.count-1;
    if (indexForEndOfSuggestion >= 0) {
        [_suggestionTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexForEndOfSuggestion inSection:0] atScrollPosition:0 animated:NO];
    }
}

#pragma mark - TextField
- (void)textFieldDidChange:(id)sender
{
    if (![_lastStringInSearchTextField isEqualToString:_searchTextField.text]) {
        [self changeSuggestionTableFrame];
        _lastStringInSearchTextField = _searchTextField.text;
        if (![_lastStringInSearchTextField isEqualToString:@""]) {
            switch (_APIType) {
                case FFFAutoSuggestionAPIGoogle:
                    [self requestXMLWithQuery:_lastStringInSearchTextField];
                    break;
                case FFFAutoSuggestionAPIDuckDuckGo:
                    [self requestJSONWithQuery:_lastStringInSearchTextField];
                default: break;
            }
            
        }
    }
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self showSuggestionTable];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self hideSuggestionTable];
}

#pragma mark - JSON
- (void)requestJSONWithQuery:(NSString *)query
{
    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *string = [NSString stringWithFormat:@"https://duckduckgo.com/ac/?q=%@", query];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"--- %@", responseObject);
        _suggestions = [(NSDictionary *)responseObject mutableArrayValueForKey:@"phrase"];
        [self refreshSuggestionTable];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OKK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    [operation start];
}

#pragma mark - XML
- (void)requestXMLWithQuery:(NSString *)query
{
    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *string = [NSString stringWithFormat:@"http://suggestqueries.google.com/complete/search?q=%@&client=toolbar", query];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSXMLParser *XMLParser = (NSXMLParser *)responseObject;
        [XMLParser setShouldProcessNamespaces:YES];
        XMLParser.delegate = self;
        [XMLParser parse];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error retrieving suggestions"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    [operation start];
}
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _suggestions = [NSMutableArray array];
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"suggestion"]) {
        [_suggestions addObject:attributeDict[@"data"]];
    }
}
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self refreshSuggestionTable];
}


#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _suggestions.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FFFTableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = _suggestions[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _searchTextField.text = _suggestions[indexPath.row];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 32.0;
}


#pragma mark - Notification
- (void)KeyboardDidChangeFrame:(NSNotification *)n
{
    if ([self.view.subviews containsObject:_suggestionTable]) {
        [self changeSuggestionTableFrame];
    }
}

@end
