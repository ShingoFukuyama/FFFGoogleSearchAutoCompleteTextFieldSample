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

@interface FFFGoogleSearchAutoCompleteController ()
<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NSXMLParserDelegate>
@property (nonatomic, strong) FFFGoogleSearchAutoCompleteTextField  *searchTextField;
@property (nonatomic, strong) NSString                              *lastStringInSearchTextField;
@property (nonatomic, strong) UITableView                           *suggestionTable;
@property (nonatomic, strong) NSMutableArray                        *suggestions;
@end

@implementation FFFGoogleSearchAutoCompleteController

static NSString *FFFTableViewCellIdentifier = @"FFFTableViewCellIdentifier";

- (void)viewDidLoad
{
    [super viewDidLoad];

    _suggestions = [NSMutableArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(KeyboardDidChangeFrame:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];

    _searchTextField = [[FFFGoogleSearchAutoCompleteTextField alloc] initWithFrame:CGRectMake(20.0, self.view.frame.size.height - 90.0, self.view.frame.size.width - 40.0, 36.0)];
    _searchTextField.delegate = self;
    [_searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:_searchTextField];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:[NSBlockOperation blockOperationWithBlock:^{
        [_searchTextField becomeFirstResponder];
    }] selector:@selector(main) userInfo:nil repeats:NO];
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

#pragma mark - TextField
- (void)textFieldDidChange:(id)sender
{
    if (![_lastStringInSearchTextField isEqualToString:_searchTextField.text]) {
        [self changeSuggestionTableFrame];
        _lastStringInSearchTextField = _searchTextField.text;
        if (![_lastStringInSearchTextField isEqualToString:@""]) {
            [self requestXMLWithQuery:_lastStringInSearchTextField];
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
    _suggestions = [[[_suggestions reverseObjectEnumerator] allObjects] mutableCopy];
    [self.suggestionTable reloadData];
    [_suggestionTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_suggestions.count-1 inSection:0] atScrollPosition:0 animated:NO];
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
