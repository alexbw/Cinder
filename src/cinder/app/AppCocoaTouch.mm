/*
 Copyright (c) 2010, The Barbarian Group
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and
 the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#include "cinder/app/AppCocoaTouch.h"
#include "cinder/cocoa/CinderCocoaTouch.h"
#include "cinder/app/CinderViewCocoaTouch.h"
#include "cinder/cocoa/CinderCocoa.h" // this is just for the renderer initialization


namespace cinder { namespace app {
	
	AppCocoaTouch*				AppCocoaTouch::sInstance = 0;
	
	// This struct serves as a compile firewall for maintaining AppCocoaTouch state information
	struct AppCocoaTouchState {
		CinderViewCocoaTouch		*mCinderView;
		UIWindow					*mWindow;
		CFAbsoluteTime				mStartTime;
	};
	
	void setupCocoaTouchWindow( AppCocoaTouch *app )
	{
		app->privatePrepareSettings__();
		app->mState->mWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		app->mState->mCinderView = [[CinderViewCocoaTouch alloc] initWithFrame:[[UIScreen mainScreen] bounds] app:app renderer:app->getRenderer()];
		[app->mState->mWindow addSubview:app->mState->mCinderView];
		[app->mState->mCinderView release];
		[app->mState->mWindow makeKeyAndVisible];
		
		app->privateSetup__();
		
		[app->mState->mCinderView startAnimation];
	}
	
	
	void setupCocoaTouchView( CinderViewCTE *cinderView, class Renderer *renderer, AppCocoaTouch *app )
	{
		
		app->prepareApp(app, renderer);
		app->privatePrepareSettings__();

		[cinderView setApp:app];
		[cinderView setRenderer:app->getRenderer()];
		
		
		app->getRenderer()->setup( app, ci::cocoa::CgRectToArea( [cinderView bounds] ), (UIView *)cinderView );
		
		app->privateSetup__();
		app->privatePrepareSettings__();
		[cinderView setMultipleTouchEnabled:app->getSettings().isMultiTouchEnabled()];

		app->mState->mCinderView = cinderView;
		[app->mState->mCinderView startAnimation];
		
	}
	
	
} } // namespace cinder::app

@interface CinderAccelerometerDelegateIPhone : NSObject <UIAccelerometerDelegate> {
	cinder::app::AppCocoaTouch *app;
}
- (id)initWithApp:(cinder::app::AppCocoaTouch *)thisApp;
@end

@implementation CinderAccelerometerDelegateIPhone


- (id)initWithApp:(cinder::app::AppCocoaTouch *)thisApp
{
	if (self = [super init]) {
		app = thisApp;
		return self;
	}
	
	return nil;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)thisAcceleration {
	// Massage the UIAcceleration class into a Vec3f
	ci::Vec3f direction( thisAcceleration.x, thisAcceleration.y, thisAcceleration.z );
	app->privateAccelerated__( direction );
}

- (void)dealloc 
{
	[super dealloc];
}

@end

@interface CinderAppDelegateIPhone : NSObject <UIApplicationDelegate> {
	cinder::app::AppCocoaTouch	*app;
	//    UIWindow				*window;
	//    CinderViewCocoaTouch	*cinderView;
}
@end

@implementation CinderAppDelegateIPhone


- (void) applicationDidFinishLaunching:(UIApplication *)application
{
	app = cinder::app::AppCocoaTouch::get();
	setupCocoaTouchWindow( app );
}

- (void) applicationWillResignActive:(UIApplication *)application
{
	//	[cinderView stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
	//	[cinderView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	//	[cinderView stopAnimation];
	app->privateShutdown__();
}

- (void) dealloc
{
	//	[window release];
	//	[cinderView release];
	
	[super dealloc];
}

@end



namespace cinder { namespace app {
		
	
	AppCocoaTouch::AppCocoaTouch()
	: App()
	{
		mState = shared_ptr<AppCocoaTouchState>( new AppCocoaTouchState() );
		mState->mStartTime = ::CFAbsoluteTimeGetCurrent();
		mLastAccel = mLastRawAccel = Vec3f::zero();
	}
	
	void AppCocoaTouch::launchEmbeddedApp( CinderViewCTE *cinderView, class Renderer *renderer )
	{

		setupCocoaTouchView(cinderView, renderer, this);
				
	}
	
	
	void AppCocoaTouch::launch( const char *title, int argc, char * const argv[] )
	{
		::UIApplicationMain( argc, const_cast<char**>( argv ), nil, @"CinderAppDelegateIPhone" );
	}
	
	int	AppCocoaTouch::getWindowWidth() const
	{
		::CGRect bounds = [mState->mCinderView bounds];
		return ::CGRectGetWidth( bounds );
	}
	
	int	AppCocoaTouch::getWindowHeight() const
	{
		::CGRect bounds = [mState->mCinderView bounds];
		return ::CGRectGetHeight( bounds );
	}
	
	//! Enables the accelerometer
	void AppCocoaTouch::enableAccelerometer( float updateFrequency, float filterFactor )
	{
		mAccelFilterFactor = filterFactor;
		
		if( updateFrequency <= 0 )
			updateFrequency = 30.0f;
		
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0 / updateFrequency];
		CinderAccelerometerDelegateIPhone *appDel = [[CinderAccelerometerDelegateIPhone alloc] initWithApp:this];
		[appDel retain];
		[[UIAccelerometer sharedAccelerometer] setDelegate:appDel];

	}
	
	void AppCocoaTouch::disableAccelerometer() {
		
		[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	}
	
	//! Returns the maximum frame-rate the App will attempt to maintain.
	float AppCocoaTouch::getFrameRate() const
	{
		return 0;
	}
	
	//! Sets the maximum frame-rate the App will attempt to maintain.
	void AppCocoaTouch::setFrameRate( float aFrameRate )
	{
	}
	
	//! Returns whether the App is in full-screen mode or not.
	bool AppCocoaTouch::isFullScreen() const
	{
		return true;
	}
	
	//! Sets whether the active App is in full-screen mode based on \a fullScreen
	void AppCocoaTouch::setFullScreen( bool aFullScreen )
	{
	}
	
	double AppCocoaTouch::getElapsedSeconds() const
	{
		CFAbsoluteTime currentTime = ::CFAbsoluteTimeGetCurrent();
		return ( currentTime - mState->mStartTime );
	}
	
	std::string AppCocoaTouch::getAppPath()
	{ 
		return [[[NSBundle mainBundle] bundlePath] UTF8String];
	}
	
	void AppCocoaTouch::quit()
	{
		return;
	}
	
	void AppCocoaTouch::privatePrepareSettings__()
	{
		prepareSettings( &mSettings );
	}
	
	void AppCocoaTouch::privateTouchesBegan__( const TouchEvent &event )
	{
		touchesBegan( event );
	}
	
	void AppCocoaTouch::privateTouchesMoved__( const TouchEvent &event )
	{
		touchesMoved( event );
	}
	
	void AppCocoaTouch::privateTouchesEnded__( const TouchEvent &event )
	{
		touchesEnded( event );
	}	
	
	void AppCocoaTouch::privateAccelerated__( const Vec3f &direction )
	{
		Vec3f filtered = mLastAccel * (1.0f - mAccelFilterFactor) + direction * mAccelFilterFactor;
		accelerated( AccelEvent( filtered, direction, mLastAccel, mLastRawAccel ) );
		mLastAccel = filtered;
		mLastRawAccel = direction;
	}
	
} } // namespace cinder::app