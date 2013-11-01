/*******************************************************************************
Copyright (c) 2010, Zdenek Vasicek (vasicek AT fit.vutbr.cz)
                    Marek Vavrusa  (marek AT vavrusa.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the organization nor the names of its
      contributors may be used to endorse or promote products derived from this
      software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE. 
*******************************************************************************/

import flash.display.Sprite;
import flash.events.Event;
import map.Canvas;
import map.LngLat;
import map.TileLayer;
import map.MapService;
import com.Button;
import com.ToolBar;
import com.StatusBar;

class Example03 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;
    var gc:OSMGeoCoding;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example03 = new Example03();
       flash.Lib.current.stage.addEventListener(Event.RESIZE, t.stageResized);
       flash.Lib.current.stage.addChildAt(t,0);
    }


    function new()
    {
        super();
   
        toolbar = new ToolBar();
        canvas = new Canvas();

        toolbar.move(0, 0);
        canvas.move(0, 0);
        canvas.setCenter(new LngLat(16.720,49.570));
        canvas.addLayer(new TileLayer(new OpenStreetMapService(14), 8));

        stageResized(null);
        initToolbar();

        addChild(canvas);
        addChild(toolbar);

        canvas.initialize();

        gc = new OSMGeoCoding();
        gc.addEventListener(OSMGeoCoding.QUERY_FINISHED, queryFinished);
    }

    public function stageResized(e:Event)
    {
        toolbar.setSize(flash.Lib.current.stage.stageWidth, 30);
        canvas.setSize(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
    }

    function queryFinished(e:Event)
    {
        toolbar.setText("Address:" + gc.address);
        canvas.setCenter(gc.point);
    }

    function initToolbar()
    {
        var me = this;
        var tf = toolbar.addTextField(200,"Božetěchova, Brno, CZ","Address:", -10);
        toolbar.addButton(new SearchButton(), "Find", function(b:CustomButton) { me.gc.query(tf.text); });

	tf.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, 
                              function(e:flash.events.KeyboardEvent) {  
                                        if (e.keyCode == flash.ui.Keyboard.ENTER) me.gc.query(tf.text);
                              }
                           );
    }

}

import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;

class OSMGeoCoding extends URLLoader {

    //Info:
    //-----------------------------------------------------------------------------
    //  http://wiki.openstreetmap.org/wiki/Nominatim

    public static var QUERY_FINISHED:String = "queryfinished";
    public var point:LngLat;
    public var address:String;

    public function new()
    {
        super();
        this.point = null;
        this.address = "";
    }

    public function query(text:String)
    {
        var request:URLRequest = new URLRequest("http://nominatim.openstreetmap.org/search");
        request.data = new URLVariables();
        request.data.format = "xml";
        request.data.q = text;
        request.method = flash.net.URLRequestMethod.GET;
        try {
            dataFormat = flash.net.URLLoaderDataFormat.TEXT;
            load(request);
            addEventListener(Event.COMPLETE, getResponse);
        } catch (unknown : Dynamic)  {
            trace("Error:"+unknown);
        };
    }

    function getResponse(e:Event) 
    {
        removeEventListener(Event.COMPLETE, getResponse);

        try {

           var resp:Xml = Xml.parse(data);
           //trace("Response:" + resp);

           var el:Xml = resp.firstElement();
           if ((el != null) && (el.nodeName == "searchresults")) {
              for (ep in el.elementsNamed("place")) 
                  if (ep.exists("lat") && ep.exists("lon") && ep.exists("display_name"))
                  {
                     this.point = new LngLat(Std.parseFloat(ep.get("lon")), Std.parseFloat(ep.get("lat")));
                     this.address = ep.get("display_name");
                     dispatchEvent(new Event(QUERY_FINISHED));
                     return;       
                  }
           }

        } catch (unknown : Dynamic)  {
           trace("Error:"+unknown);
        };
    }
}
