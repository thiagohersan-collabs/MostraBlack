package com.hersan.mostrablack;


import java.util.*; 

import android.content.BroadcastReceiver; 
import android.content.Context; 
import android.content.Intent;
import android.content.IntentFilter;
import android.app.Activity;
import android.os.Bundle; 
import android.telephony.SmsMessage; 
import android.view.MotionEvent; 
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiInfo;

import twitter4j.*;
import twitter4j.auth.*;

import oscP5.*;
import netP5.*;


public class SmsClientActivity extends Activity {

	// twitter keys for umacasaumlar
	static String cKey = "SlEzMqoJaStghRet8CVPINtQ";
	static String cSec = "T5t1Q5cU4kN6NUdM5giWtghMrCBuhU2VthbqnSZZWauEY";
	static String aKey = "311667113-cpiEaL0ffSHuVMtghQR2RbqjnmJgcyhRwqfDizBBalL";
	static String aSec = "TptQfK2dOhNopgakGnnucXuMtghG2IyEs2kjUtlTIAcI";

	private boolean USETWITTER = false;

	// what to look for and clean up
	static String lookClean  = "umacasaumlar";
	static String lookClean2 = "oquefazdeumacasaumlar";

	// for communicating
	String WALLADDR = "192.168.1.188";
	static final int    OSCPORT  = 7777;

	// Twitter
	Twitter ttt = null;
    TwitterStream tttStream = null;

    // osc
    OscP5 myOsc = null;
    NetAddress remoteAddress = null;

	// instance of my activity's receiver...
	SMSReceiver mir = null;
	
	// instance of my internet activity receiver
	NetInfoReceiver nir = null;
	
	// queue for messages
	Queue<OscMessage> msgQueue = null;

	// connectivity manager
	ConnectivityManager myConnManager = null;
	
	// x,y vars for debugging
	int mX, mY;

	private String getIP() {
		WifiManager wifiManager = (WifiManager) getSystemService(WIFI_SERVICE);
		WifiInfo wifiInfo = wifiManager.getConnectionInfo();
		int ip = wifiInfo.getIpAddress();
		
		String ipString = String.format("%d.%d.%d.%d", (ip & 0xff), (ip>>8)&0xff, (ip>>16)&0xff, (ip>>24)&0xff);
		return ipString;
	}

	// hack.
	// just checks to see if my ip is in the same domain as requested ip
	//  and if I have a wifi connection
	private boolean isConnected(String host) {
		myConnManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
    	NetworkInfo ni = myConnManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);

    	if(ni.isConnected() == false){
    		System.out.println("wifi not conn?");
    		return false;
    	}

    	String myIP = getIP();
    	String[] myIPArray = myIP.split("\\.");
    	String[] hostIPArray = host.split("\\.");
    	
    	for(int i=0; i<3; i++){
    		if(!(myIPArray[i].equals(hostIPArray[i]))){
    			System.out.println("my - host: "+myIPArray[i]+" - "+hostIPArray[i]);
    			return false;
    		}
    	}    	
    	return true;
	}
	
	// event to grab mouse touches
	// mostly for debugging...
	@Override
	public boolean dispatchTouchEvent(MotionEvent event){
		if(event.getAction() == MotionEvent.ACTION_UP){
			mX = (int)event.getX();
			mY = (int)event.getY();

			System.out.println("Client: writing to socket: "+mX+","+mY);

			String message = new String(mX+","+mY);

			OscMessage myMsg = new OscMessage("/android/debug");
		    myMsg.add(message); // add string to msg
	    	msgQueue.add(myMsg);

	    	// if I have connection to the wall, send queue...
	    	if(isConnected(WALLADDR) == true) {
	    		while(!(msgQueue.isEmpty())) {
	    			OscMessage myQMsg = msgQueue.remove();
	    			myOsc.send(myQMsg, remoteAddress);
	    		}
	    	}
		}
		return true;
	}

	
	// status listener implementation
	StatusListener sListener = new StatusListener() {
		public void onStatus(Status status) {
			System.out.println("Client Twitter Listener got: " + status.getText());

			String message = new String(status.getText());

			// clean up the @/# if it's there...
			message = message.replaceAll("[@#]?"+lookClean2, "");
			message = message.replaceAll("[@#]?"+lookClean, "");

			// write twitter out to osc
			OscMessage myMsg = new OscMessage("/android/twitter");
		    myMsg.add(message); // add string to msg
	    	msgQueue.add(myMsg);
		    
		    // if I have wifi connection to the wall, send queue..
	    	if(isConnected(WALLADDR) == true) {
	    		while(!(msgQueue.isEmpty())) {
	    			OscMessage myQMsg = msgQueue.remove();
	    			myOsc.send(myQMsg, remoteAddress);
	    		}
		    }

		}

		public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
			//System.out.println("status deletion notice id:" + statusDeletionNotice.getStatusId());
		}
		public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
			//System.out.println("track limitation notice:" + numberOfLimitedStatuses);
		}
		public void onScrubGeo(long userId, long upToStatusId) {
			//System.out.println("scrub_geo. userId:" + userId + " upToStatusId:" + upToStatusId);
		}
		public void onException(Exception ex) {
			ex.printStackTrace();
		}
	};

	
	// osc message listener
	//  gets messages from other source, 
	//  sends to wall, 
	//  checks its length and posts on twitter
	public void oscEvent(OscMessage theOscMessage) {
		// got message from hp
		//  - clean it up
		//  - send to wall
		//  - send to twitter
		if ((theOscMessage.addrPattern()).equals("/hp")) {
			String message = (theOscMessage.get(0)).stringValue();

			// clean up the @/# if it's there...
			message = message.replaceAll("[@#]?"+lookClean2, "");
			message = message.replaceAll("[@#]?"+lookClean, "");

			System.out.println("got from osc: "+message);

			// send to osc
			OscMessage myMsg = new OscMessage("/android/hp");
		    myMsg.add(message); // add string to msg
	    	msgQueue.add(myMsg);

		    // if I have wifi connection to the wall, send to wall
	    	if(isConnected(WALLADDR) == true) {
	    		while(!(msgQueue.isEmpty())) {
	    			OscMessage myQMsg = msgQueue.remove();
	    			myOsc.send(myQMsg, remoteAddress);
	    		}
		    }

	    	// check if it is to use twiter
	    	if(USETWITTER == true) {
	    		// check size and send to twitter
	    		// stupid API... check for length > 140
	    		if(message.length() > 140) {
	    			message = message.substring(0, 135);
	    			message = message.concat("...");
	    		}

	    		// try to send to twitter, but don't worry about it too much
	    		//    (there is no twitter queue)
	    		try {
	    			ttt.updateStatus(message);
	    		}
	    		catch(TwitterException e) {
	    			System.out.println("failed to post tweet");
	    		}
	    	}
		}
		
		else if ((theOscMessage.addrPattern()).equals("/ip")) {
			String message = (theOscMessage.get(0)).stringValue();
			WALLADDR = message;
			remoteAddress = new NetAddress(WALLADDR, OSCPORT);
			System.out.println("new walladdr: "+WALLADDR);
		}

	}


	// listen for intent sent by broadcast of SMS signal
	// if it gets a new SMS
	//  clean it up a little bit
	//  send to wall
	//  check its length
	//  send to twitter
	public class SMSReceiver extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {
			Bundle bundle = intent.getExtras();
			SmsMessage[] msgs = null;

			if (bundle != null) {
				Object[] pdus = (Object[]) bundle.get("pdus");
				msgs = new SmsMessage[pdus.length];

				if (msgs.length >= 0) {
					// read only the most recent
					msgs[0] = SmsMessage.createFromPdu((byte[]) pdus[0]);
					String message = msgs[0].getMessageBody().toString();
					String phoneNum = msgs[0].getOriginatingAddress().toString();
					System.out.println("Client MainAction got sms: "+message);
					System.out.println("from: "+phoneNum);

					// only write if it's from a real number
					// TEST THIS!!!!!
					if(phoneNum.length() > 5) {
						// clean up the @/# if it's there...
						message = message.replaceAll("[@#]?"+lookClean2, "");
						message = message.replaceAll("[@#]?"+lookClean, "");

						// send to osc
						OscMessage myMsg = new OscMessage("/android/sms");
						myMsg.add(message); // add string to msg
				    	msgQueue.add(myMsg);

				    	// if I have connection to wall, send queue
				    	if(isConnected(WALLADDR) == true) {
				    		while(!(msgQueue.isEmpty())) {
				    			OscMessage myQMsg = msgQueue.remove();
				    			myOsc.send(myQMsg, remoteAddress);
				    		}
				    	}

				    	if(USETWITTER == true) {
				    		// stupid API... check for length > 140
				    		if(message.length() > 140) {
				    			message = message.substring(0, 135);
				    			message = message.concat("...");
				    		}

				    		// send to twitter
				    		//    don't worry if it fails (there is no twitter queue)
				    		try {
				    			ttt.updateStatus(message);
				    		}
				    		catch(TwitterException e) {
				    			System.out.println("failed to post tweet");
				    		}
				    	}
					}
				}
			}
		}
	}


	public class NetInfoReceiver extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {

			NetworkInfo activeNetworkInfo = myConnManager.getActiveNetworkInfo();

			// if I am disconnecting, kill twitter stream
			if((activeNetworkInfo == null)||(activeNetworkInfo.getState() == NetworkInfo.State.DISCONNECTING)) {
				System.out.println("network disconnecting!");
				if(USETWITTER){
					System.out.println("killing twitter stream");
					if(tttStream != null) {
						tttStream.cleanUp();
						tttStream.shutdown();
						tttStream = null;
					}
				}
			}

			// else if connected check for paths to wall and twitter
		    else  if((activeNetworkInfo != null)&&(activeNetworkInfo.getState() == NetworkInfo.State.CONNECTED)) {
				// if I have a connection to the wall, send messages
		    	if(isConnected(WALLADDR) == true) {
		    		// send oscs to wall
		    		while(!(msgQueue.isEmpty())) {
		    			OscMessage myMsg = msgQueue.remove();
		    			myOsc.send(myMsg, remoteAddress);
		    		}
		    	}

		    	if(USETWITTER){
		    		//  if no stream, start twitter stream
		    		if(tttStream == null) {
		    			System.out.println("starting twitter stream again");
		    			tttStream = new TwitterStreamFactory().getInstance();
		    			tttStream.setOAuthConsumer(cKey, cSec);
		    			tttStream.setOAuthAccessToken(new AccessToken(aKey, aSec));

		    			// new status stream listener
		    			tttStream.addListener(sListener);
		    			FilterQuery fQ = new FilterQuery();
		    			String[] trackStrings = {"@"+lookClean, "#"+lookClean, "#"+lookClean2};
		    			fQ.track(trackStrings);
		    			tttStream.filter(fQ);
		    		}
		    	}
		    }

		}
	}

	

	// start an osc socket for communicating with wall and hp
	// start a twitter connection for writing
	// start a twitter stream connection for reading
	// start a sms listener
	@Override
	public void onCreate(Bundle b){
		super.onCreate(b);
		System.out.println("from OnCreate");

		// new sms listener
		if(mir == null) {
			mir = new SMSReceiver();
		}

		// new net info listener
		if(nir == null) {
			nir = new NetInfoReceiver();
		}
		
		// new osc
		if(myOsc == null){
			myOsc = new OscP5(this,OSCPORT);
		}
		if(remoteAddress == null) {
			remoteAddress = new NetAddress(WALLADDR, OSCPORT);
		}

		if(USETWITTER){
			// new twitter connections
			if(ttt == null) {
				ttt = new TwitterFactory().getInstance();
				ttt.setOAuthConsumer(cKey, cSec);
				ttt.setOAuthAccessToken(new AccessToken(aKey, aSec));
			}
			// new twitter stream
			if(tttStream == null) {
				tttStream = new TwitterStreamFactory().getInstance();
				tttStream.setOAuthConsumer(cKey, cSec);
				tttStream.setOAuthAccessToken(new AccessToken(aKey, aSec));

				// new status stream listener
				tttStream.addListener(sListener);
				FilterQuery fQ = new FilterQuery();
				String[] trackStrings = {"@"+lookClean, "#"+lookClean, "#"+lookClean2};
				fQ.track(trackStrings);
				tttStream.filter(fQ);
			}
		}

		// new queue
		if(msgQueue == null){
			msgQueue = new LinkedList<OscMessage>();
		}

		// new conn manager
		if(myConnManager == null){
			myConnManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
		}

	}

	// dynamically register the receiver, since it is declared 
	// and instantiated "on the fly"
	@Override
	public void onResume() {
		super.onResume();
		IntentFilter smsIF = new IntentFilter("android.provider.Telephony.SMS_RECEIVED");
		registerReceiver(mir, smsIF);

		IntentFilter netIF = new IntentFilter("android.net.conn.CONNECTIVITY_CHANGE");
		registerReceiver(nir, netIF);

	}
	@Override
    protected void onPause() {
        unregisterReceiver(mir);
        unregisterReceiver(nir);
		super.onPause();
    }

	// stop the twitter stream and connections on the way out
	@Override
	protected void onDestroy() {
		if(USETWITTER){
			tttStream.cleanUp();
			tttStream.shutdown();
		}
		super.onDestroy();
	}
}

