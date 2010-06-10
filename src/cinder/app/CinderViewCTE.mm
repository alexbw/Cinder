//
//  CinderViewCTE.mm
//  cinder
//
//  Created by Alex Wiltschko on 6/9/10.
//  Copyright 2010 University of Michigan. All rights reserved.
//


#include "cinder/app/CinderViewCTE.h"
#include "cinder/cocoa/CinderCocoa.h" // this is just for the renderer initialization

@implementation CinderViewCTE
@synthesize animating, animationTimer;
@synthesize mApp, mRenderer;

@synthesize animationFrameInterval;


// TODO: HACKY HACKY HACK HACK 
static Boolean sIsEaglLayer = TRUE;


- (void)dealloc {
    [super dealloc];
}



+ (Class) layerClass
{
	if( sIsEaglLayer )
		return [CAEAGLLayer class];
	else
		return [CALayer class];
}

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	// This needs to get setup immediately as +layerClass will be called when the view is initialized
//	sIsEaglLayer = mRenderer->isEaglLayer();
	
	if ((self = [super initWithCoder:aDecoder])) {		

		animating	 = FALSE;
		animationFrameInterval = 1.0/30.0;
		animationTimer = nil;
		mApp = nil;
		mRenderer = nil;
		self.multipleTouchEnabled = FALSE;
		
	}
	
	return self;
}


- (id)initWithFrame:(CGRect)frame {
	
	// This needs to get setup immediately as +layerClass will be called when the view is initialized
//	sIsEaglLayer = renderer->isEaglLayer();
	
    if ((self = [super initWithFrame:frame])) {
		animating	 = FALSE;
		animationFrameInterval = 1.0/30.0;
		animationTimer = nil;
		mApp = nil;
		mRenderer = nil;
		self.multipleTouchEnabled = FALSE;
		
    }
    return self;
}

// TODO: should be BOOL to indicate failure/success?
// TODO: should save a state whether or not the app is running?
- (void)launchApp
{
	if ([self ableToDraw] & !animating) // must have the app & renderer, and must not already be animating
	{
		
		mApp->launchEmbeddedApp( (CinderViewCTE *)self, (ci::app::Renderer *)mRenderer );
		
		// mRenderer->setup( mApp, ci::cocoa::CgRectToArea( [self bounds] ), self );

		// self.multipleTouchEnabled = mApp->getSettings().isMultiTouchEnabled();
		
		// [self startAnimation];
		
	}
}


- (BOOL)ableToDraw
{
	return (mApp != nil) & (mRenderer != nil);
}


# pragma mark - Drawing methods

- (void) layoutSubviews
{
	
	if (![self ableToDraw])
		return;
	
	CGRect bounds = [self bounds];
	mRenderer->setFrameSize( bounds.size.width, bounds.size.height );
	mApp->privateResize__( bounds.size.width, bounds.size.height );
	[self drawView:nil];
	
}

- (void)drawView:(id)sender
{
	
	if (![self ableToDraw]) // If we don't have an app or a renderer yet, bail out
		return;
	
//	if( sIsEaglLayer ) {
//		mRenderer->startDraw();
//		mApp->privateUpdate__();
//		mApp->privateDraw__();
//		mRenderer->finishDraw();
//	}
	
	else
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:self waitUntilDone:NO];
}



- (void)startAnimation
{
	if( ( animationTimer == nil ) || ( ! [animationTimer isValid] ) ) {
		animationTimer = [NSTimer	 timerWithTimeInterval:animationFrameInterval
												  target:self
												selector:@selector(timerFired:)
												userInfo:nil
												 repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:animationTimer forMode:NSDefaultRunLoopMode];
	}	
	
	animating = TRUE;
	
}

- (void)timerFired:(NSTimer *)t
{
	mApp->privateUpdate__();
	
	if (!self.hidden) // NOTE: this is probably NOT the most general way to detect if a view needs drawing
	{
		mRenderer->startDraw();
		mApp->privateDraw__();
		mRenderer->finishDraw();
	}
	
}

- (void)stopAnimation
{
	[animationTimer invalidate];
	animationTimer = nil;	
	animating = FALSE;
}



- (void)setApp:(ci::app::AppCocoaTouch *)app
{
	mApp = app;
}

- (ci::app::AppCocoaTouch *)getApp
{
	return mApp;
}

- (void)setRenderer:(ci::app::Renderer *)renderer
{
	mRenderer = renderer;
}

- (ci::app::Renderer *)getRenderer
{
	return mRenderer;
}









- (uint32_t)addTouchToMap:(UITouch*)touch
{
	uint32_t candidateId = 0;
	bool found = true;
	while( found ) {
		candidateId++;
		found = false;
		for( std::map<UITouch*,uint32_t>::const_iterator mapIt = mTouchIdMap.begin(); mapIt != mTouchIdMap.end(); ++mapIt ) {
			if( mapIt->second == candidateId ) {
				found = true;
				break;
			}
		}
	}
	
	mTouchIdMap.insert( std::make_pair( touch, candidateId ) );
	
	return candidateId;
}

- (void)removeTouchFromMap:(UITouch*)touch
{
	std::map<UITouch*,uint32_t>::iterator found( mTouchIdMap.find( touch ) );
	if( found == mTouchIdMap.end() )
		;//std::cout << "Couldn' find touch in map?" << std::endl;
	else
		mTouchIdMap.erase( found );
}

- (uint32_t)findTouchInMap:(UITouch*)touch
{
	std::map<UITouch*,uint32_t>::const_iterator found( mTouchIdMap.find( touch ) );
	if( found == mTouchIdMap.end() ) {
		;//std::cout << "Couldn' find touch in map?" << std::endl;
		return 0;
	}
	else
		return found->second;
}

- (void)updateActiveTouches
{
	std::vector<ci::app::TouchEvent::Touch> activeTouches;
	for( std::map<UITouch*,uint32_t>::const_iterator touchIt = mTouchIdMap.begin(); touchIt != mTouchIdMap.end(); ++touchIt ) {
		CGPoint pt = [touchIt->first locationInView:self];
		CGPoint prevPt = [touchIt->first previousLocationInView:self];
		activeTouches.push_back( ci::app::TouchEvent::Touch( ci::Vec2f( pt.x, pt.y ), ci::Vec2f( prevPt.x, prevPt.y ), touchIt->second, [touchIt->first timestamp], touchIt->first ) );
	}
	mApp->privateSetActiveTouches__( activeTouches );
}

/////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	if( mApp->getSettings().isMultiTouchEnabled() ) {
		std::vector<ci::app::TouchEvent::Touch> touchList;
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];
			CGPoint prevPt = [touch previousLocationInView:self];
			touchList.push_back( ci::app::TouchEvent::Touch( ci::Vec2f( pt.x, pt.y ), ci::Vec2f( prevPt.x, prevPt.y ), [self addTouchToMap:touch], [touch timestamp], touch ) );
		}
		[self updateActiveTouches];
		if( ! touchList.empty() )
			mApp->privateTouchesBegan__( ci::app::TouchEvent( touchList ) );
	}
	else {
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];		
			int mods = 0;
			mods |= cinder::app::MouseEvent::LEFT_DOWN;
			mApp->privateMouseDown__( cinder::app::MouseEvent( cinder::app::MouseEvent::LEFT_DOWN, pt.x, pt.y, mods, 0.0f, 0 ) );
		}
	}
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	if( mApp->getSettings().isMultiTouchEnabled() ) {
		std::vector<ci::app::TouchEvent::Touch> touchList;
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];
			CGPoint prevPt = [touch previousLocationInView:self];			
			touchList.push_back( ci::app::TouchEvent::Touch( ci::Vec2f( pt.x, pt.y ), ci::Vec2f( prevPt.x, prevPt.y ), [self findTouchInMap:touch], [touch timestamp], touch ) );
		}
		[self updateActiveTouches];
		if( ! touchList.empty() )
			mApp->privateTouchesMoved__( ci::app::TouchEvent( touchList ) );
	}
	else {
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];		
			int mods = 0;
			mods |= cinder::app::MouseEvent::LEFT_DOWN;
			mApp->privateMouseDrag__( cinder::app::MouseEvent( cinder::app::MouseEvent::LEFT_DOWN, pt.x, pt.y, mods, 0.0f, 0 ) );
		}
	}
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if( mApp->getSettings().isMultiTouchEnabled() ) {
		std::vector<ci::app::TouchEvent::Touch> touchList;
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];
			CGPoint prevPt = [touch previousLocationInView:self];
			touchList.push_back( ci::app::TouchEvent::Touch( ci::Vec2f( pt.x, pt.y ), ci::Vec2f( prevPt.x, prevPt.y ), [self findTouchInMap:touch], [touch timestamp], touch ) );
			[self removeTouchFromMap:touch];
		}
		[self updateActiveTouches];
		if( ! touchList.empty() )
			mApp->privateTouchesEnded__( ci::app::TouchEvent( touchList ) );
	}
	else {
		for( UITouch *touch in touches ) {
			CGPoint pt = [touch locationInView:self];		
			int mods = 0;
			mods |= cinder::app::MouseEvent::LEFT_DOWN;
			mApp->privateMouseUp__( cinder::app::MouseEvent( cinder::app::MouseEvent::LEFT_DOWN, pt.x, pt.y, mods, 0.0f, 0 ) );
		}
	}
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self touchesEnded:touches withEvent:event];
}

@end
