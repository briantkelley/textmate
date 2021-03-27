#import "MBMenuDelegate.h"

@interface MBProxyMenuItem : NSMenuItem
@end

@implementation MBProxyMenuItem
- (void)tmSendAction:(id)sender
{
	[NSApp sendAction:self.action to:self.target from:self];
	self.target = nil;
	self.representedObject = nil;
}
@end

@interface MBKeyEquivalentMenu : NSMenu
@end

@implementation MBKeyEquivalentMenu
- (NSMenuProperties)propertiesToUpdate
{
	return NSMenuPropertyItemKeyEquivalent;
}
@end

@interface MBMenuDelegate ()
@property (nonatomic) MBProxyMenuItem* proxyMenuItem;
@end

@implementation MBMenuDelegate
+ (instancetype)sharedInstance
{
	static MBMenuDelegate* sharedInstance = [self new];
	return sharedInstance;
}

- (BOOL)isShowTabMenu:(NSMenu*)aMenu
{
	return [aMenu.title isEqualToString:@"Show Tab"];
}

- (void)updateMenu:(NSMenu*)aMenu withSelector:(SEL)aSelector
{
	[aMenu removeAllItems];
	if(id delegate = [NSApp targetForAction:aSelector])
			[NSApp sendAction:aSelector to:delegate from:aMenu];
	else	[aMenu addItemWithTitle:@"no items" action:NULL keyEquivalent:@""];
}

- (void)menuNeedsUpdate:(NSMenu*)aMenu
{
	[self updateMenu:aMenu withSelector:[self isShowTabMenu:aMenu] ? @selector(updateShowTabMenu:) : @selector(updateBookmarksMenu:)];
}

- (BOOL)menuHasKeyEquivalent:(NSMenu*)aMenu forEvent:(NSEvent*)anEvent target:(id*)anId action:(SEL*)aSEL
{
	if(![self isShowTabMenu:aMenu])
		return NO;

	NSUInteger flags     = anEvent.modifierFlags & (NSEventModifierFlagCommand|NSEventModifierFlagShift|NSEventModifierFlagControl|NSEventModifierFlagOption);
	NSString* characters = anEvent.characters;
	if(flags != NSEventModifierFlagCommand || characters.length != 1 || ![NSCharacterSet.decimalDigitCharacterSet characterIsMember:[characters characterAtIndex:0]])
		return NO;

	NSMenu* dummy = [MBKeyEquivalentMenu new];
	[self updateMenu:dummy withSelector:@selector(updateShowTabMenu:)];
	for(NSMenuItem* item in [dummy itemArray])
	{
		if(item.keyEquivalentModifierMask == flags && [item.keyEquivalent isEqualToString:characters])
		{
			if(!self.proxyMenuItem)
				self.proxyMenuItem = [MBProxyMenuItem new];

			self.proxyMenuItem.action            = item.action;
			self.proxyMenuItem.target            = item.target;
			self.proxyMenuItem.tag               = item.tag;
			self.proxyMenuItem.representedObject = item.representedObject;

			*anId = self.proxyMenuItem;
			*aSEL = @selector(tmSendAction:);

			return YES;
		}
	}
	return NO;
}
@end