#include "cinder/app/AppBasic.h"
#include "cinder/audio/Io.h"
#include "cinder/audio/Output.h"
#include "cinder/audio/FftProcessor.h"

#include "Resources.h"
using namespace ci;
using namespace ci::app;
using namespace std;

#define kBandCount 64
#define kFFTHistory 5

class WelchPeriodogram {
public:
	float *fftHistory[kFFTHistory];
	float *fftDisplayBuffer;
	float *getFft() { return fftDisplayBuffer; }
	
	WelchPeriodogram() {};
	
	WelchPeriodogram(int numBands)
	{
		for (int i=0; i < kFFTHistory; ++i)
			fftHistory[i] = new float[numBands];
		
		fftDisplayBuffer = new float[numBands];
		
	}
	
	void addFft(const float *fftBuffer) 
	{
		static int iFFT = kFFTHistory;
		if (iFFT >= kFFTHistory)
			iFFT = 0;
		
		memset(fftDisplayBuffer, 0, sizeof(fftDisplayBuffer));
		for (int i=0; i < kBandCount; ++i)
		{
			fftHistory[iFFT][i] = fftBuffer[i];
			for (int j=0; j < kFFTHistory; ++j)
				fftDisplayBuffer[i] += fftHistory[j][i];
			fftDisplayBuffer[i] /= (float)kBandCount;
			
		}
		
		iFFT++;
		
	}
	
};


// We'll create a new Cinder Application by deriving from the AppBasic class
class AudioAnalysisSampleApp : public AppBasic {
 public:
	void setup();
	void draw();
	void drawWaveForm( audio::TrackRef track );
	void drawFft( audio::TrackRef track );
	void keyDown( KeyEvent e );
	
	WelchPeriodogram *welch;
	
	audio::TrackRef mTrack1;
	audio::TrackRef mTrack2;
	
	AudioAnalysisSampleApp()
	{
		welch = new WelchPeriodogram(kBandCount);
	}
		
private:
	

	
};

void AudioAnalysisSampleApp::setup()
{
	//mTrack1 = audio::Output::addTrack( audio::load( "C:\\code\\cinder\\samples\\AudioPlayback\\resources\\booyah.mp3" ) );
	//mTrack1->setPcmBuffering( true );
	mTrack1 = audio::Output::addTrack( audio::load( loadResource( RES_TTV ) ) );
	mTrack1->setPcmBuffering( true );
	//mTrack2 = audio::Output::addTrack( audio::load( loadResource( RES_DRUMS ) ) );
	//mTrack2->setPcmBuffering( true );
}

void AudioAnalysisSampleApp::keyDown( KeyEvent e ) {
	if( e.getChar() == 'p' ) {
		( mTrack1->isPlaying() ) ? mTrack1->stop() : mTrack1->play();
	}
}

void AudioAnalysisSampleApp::drawWaveForm( audio::TrackRef track )
{
	
	
	audio::PcmBuffer32fRef aPcmBuffer = track->getPcmBuffer();
	if( ! aPcmBuffer ) {
		return;
	}
	

	
	uint32_t bufferSamples = aPcmBuffer->getSampleCount();

	
	audio::Buffer32fRef leftBuffer = aPcmBuffer->getChannelData( audio::CHANNEL_FRONT_LEFT );
	audio::Buffer32fRef rightBuffer = aPcmBuffer->getChannelData( audio::CHANNEL_FRONT_RIGHT );

	int displaySize = getWindowWidth();
	int endIdx = bufferSamples;
	
	float scale = displaySize / (float)endIdx;
	
	glColor3f( 1.0f, 0.5f, 0.25f );
	glBegin( GL_LINE_STRIP );
	for( int i = 0; i < endIdx; i++ ) {
		float y = ( ( leftBuffer->mData[i] - 1 ) * - 100 );
		glVertex2f( ( i * scale ) , y );
	}
	glEnd();
	
	glColor3f( 1.0f, 0.96f, 0.0f );
	glBegin( GL_LINE_STRIP );
	for( int i = 0; i < endIdx; i++ ) {
		float y = ( ( rightBuffer->mData[i] - 1 ) * - 100 );
		glVertex2f( ( i * scale ) , y );
	}
	glEnd();
}

void AudioAnalysisSampleApp::drawFft( audio::TrackRef track )
{

	
	float ht = (float)getWindowHeight();

	float dutyCycle = 0.8;
	float barWidth = (float)getWindowWidth()/(float)kBandCount;
		
	audio::PcmBuffer32fRef aPcmBuffer = track->getPcmBuffer();
	if( ! aPcmBuffer ) {
		return;
	}
	boost::shared_ptr<float> fftRef = audio::calculateFft( aPcmBuffer->getChannelData( audio::CHANNEL_FRONT_LEFT ), kBandCount );
	if( ! fftRef ) {
		return;
	}
	
	float * fftBuffer = fftRef.get();
	
	welch->addFft(fftBuffer);
	
	float * fftDisplayBuffer = welch->getFft();
	
// float *fftDisplayBuffer = fftRef.get();
	
	for( int i = 0; i < ( kBandCount ); i++ ) {
		float barY = 10.0f*kFFTHistory*fftDisplayBuffer[i] / kBandCount * ht;
		glBegin( GL_QUADS );
			glColor3f( 255.0f, 255.0f, 0.0f );
			glVertex2f( i * barWidth, ht );
			glVertex2f( i * barWidth + barWidth*dutyCycle, ht );
			glColor3f( 0.0f, 255.0f, 0.0f );
			glVertex2f( i * barWidth + barWidth*dutyCycle, ht - barY );
			glVertex2f( i * barWidth, ht - barY );
		glEnd();
	}
}

void AudioAnalysisSampleApp::draw()
{
	gl::clear( Color( 0.0f, 0.0f, 0.0f ) );
	
	glPushMatrix();
		glTranslatef( 0.0, 0.0, 0.0 );
		drawFft( mTrack1 );
		drawWaveForm( mTrack1 );
		glTranslatef( 0.0, 120.0, 0.0 );
		//drawFft( mTrack2 );
		//drawWaveForm( mTrack2 );
	glPopMatrix();
}

// This line tells Cinder to actually create the application
CINDER_APP_BASIC( AudioAnalysisSampleApp, RendererGl )
