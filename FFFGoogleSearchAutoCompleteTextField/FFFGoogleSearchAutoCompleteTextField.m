//
//  FFFGoogleSearchAutoCompleteTextField.m
//  FFFGoogleSearchAutoCompleteTextField
//
//  Created by FukuyamaShingo on 7/17/14.
//  Copyright (c) 2014 ShingoFukuyama. All rights reserved.
//

#import "FFFGoogleSearchAutoCompleteTextField.h"

@interface FFFGoogleSearchAutoCompleteTextField ()
@property (nonatomic, assign) CGRect  labelOriginalRect;
@property (nonatomic, strong) NSTimer *timerForBackwarding;
@property (nonatomic, strong) NSTimer *timerForForwarding;
@end


@implementation FFFGoogleSearchAutoCompleteTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _labelOriginalRect = frame;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 15.0;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification
                                                   object:nil];

        CGRect windowFrame = [[UIScreen mainScreen] bounds];
        UIToolbar *accessoryBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, windowFrame.size.width, 44.0)];

        UIBarButtonItem *space1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space2.width = 10.0;

        UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearTextField:)];
        clearItem.width = 50.0;

        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard:)];
        closeItem.width = 50.0;

        UIBarButtonItem *backwardItem = [[UIBarButtonItem alloc] init];
        backwardItem.width = 20.0;
        UILabel *labelForBackwardItem = [[UILabel alloc] initWithFrame:CGRectMake(0, 7.0, 30.0, 20.0)];
        labelForBackwardItem.text = @"<";
        labelForBackwardItem.textColor = [UIColor colorWithRed:0.245 green:0.464 blue:1.000 alpha:1.000];
        labelForBackwardItem.userInteractionEnabled = YES;
        backwardItem.customView = labelForBackwardItem;
        UITapGestureRecognizer *tapBackwardItem = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveCursorPositionPrevious)];
        [labelForBackwardItem addGestureRecognizer:tapBackwardItem];
        UILongPressGestureRecognizer *longPressBackwardItem = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveCursorPositionPreviousContinuously:)];
        longPressBackwardItem.minimumPressDuration = 0.37;
        [labelForBackwardItem addGestureRecognizer:longPressBackwardItem];

        UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] init];
        forwardItem.width = 20.0;
        UILabel *labelForForwardItem = [[UILabel alloc] initWithFrame:CGRectMake(0, 7.0, 30.0, 20.0)];
        labelForForwardItem.text = @">";
        labelForForwardItem.textColor = [UIColor colorWithRed:0.245 green:0.464 blue:1.000 alpha:1.000];
        labelForForwardItem.userInteractionEnabled = YES;
        forwardItem.customView = labelForForwardItem;
        UITapGestureRecognizer *tapForwardItem = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveCursorPositionNext)];
        [labelForForwardItem addGestureRecognizer:tapForwardItem];
        UILongPressGestureRecognizer *longPressForwardItem = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveCursorPositionNextContinuously:)];
        longPressForwardItem.minimumPressDuration = 0.37;
        [labelForForwardItem addGestureRecognizer:longPressForwardItem];

        accessoryBar.items = @[clearItem, space1, backwardItem, space2, forwardItem, space1, closeItem];

        self.inputAccessoryView = accessoryBar;
    }
    return self;
}
// Placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 10.0, 3.0);
}
// Text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 10.0, 3.0);
}

#pragma mark - Keyboard additional buttons
- (void)clearTextField:(id)sender
{
    self.text = @"";
}
- (void)dismissKeyboard:(id)sender
{
    [self resignFirstResponder];
}
#pragma mark Move Cursor Position
- (void)moveCursorPositionPreviousContinuously:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        [_timerForBackwarding invalidate];
        _timerForBackwarding = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                target:[NSBlockOperation blockOperationWithBlock:^{
            [self moveCursorPositionPrevious];
        }] selector:@selector(main) userInfo:nil repeats:YES];
    } else if (gr.state == UIGestureRecognizerStateEnded) {
        [_timerForBackwarding invalidate];
    }
}
- (void)moveCursorPositionNextContinuously:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        [_timerForForwarding invalidate];
        _timerForForwarding = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                target:[NSBlockOperation blockOperationWithBlock:^{
            [self moveCursorPositionNext];
        }] selector:@selector(main) userInfo:nil repeats:YES];
    } else if (gr.state == UIGestureRecognizerStateEnded) {
        [_timerForForwarding invalidate];
    }
}
- (void)moveCursorPositionNext
{
    NSRange range = [self selectedRangeWithLocationOffset:1];
    if (range.location <= self.text.length) {
        [self moveCursorPosition:range];
    }
}
- (void)moveCursorPositionPrevious
{
    NSRange range = [self selectedRangeWithLocationOffset:-1];
    [self moveCursorPosition:range];
}
- (void)moveCursorPosition:(NSRange)range
{
    UITextPosition *start = [self positionFromPosition:[self beginningOfDocument] offset:range.location];
    UITextPosition *end = [self positionFromPosition:start offset:range.length];
    self.selectedTextRange = [self textRangeFromPosition:start toPosition:end];
}
- (NSRange)selectedRangeWithLocationOffset:(NSInteger)offset
{
    // http://stackoverflow.com/questions/21149767/convert-selectedtextrange-uitextrange-to-nsrange
    UITextPosition* beginning = self.beginningOfDocument;
    UITextRange* selectedRange = self.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    return NSMakeRange(location + offset, length);
}


#pragma mark - Keyboard Animation
- (void)keyboardWillShow:(NSNotification *)n
{
    CGRect keyboardFrame = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float keyboardAnimationDuration = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve keyboardAnimationCurve = [[n.userInfo
                                                    objectForKey:UIKeyboardAnimationCurveUserInfoKey]
                                                   integerValue];

    [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:(keyboardAnimationCurve << 16) animations:^{
        self.center = CGPointMake(keyboardFrame.size.width/2.0, keyboardFrame.origin.y-self.frame.size.height/2.0);
    } completion:^(BOOL finished) {}];

}
- (void)keyboardWillHide:(NSNotification *)n
{
    float keyboardAnimationDuration = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.frame = _labelOriginalRect;
    } completion:^(BOOL finished) {}];
}

@end
