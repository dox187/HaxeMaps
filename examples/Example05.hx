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
import map.MapService;
import com.Button;
import com.ToolBar;
import com.InfoBox;

class Example05 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;
    var infobox:InfoBox;
    var layer:map.TileLayer;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example05 = new Example05();
       flash.Lib.current.stage.addEventListener(Event.RESIZE, t.stageResized);
       flash.Lib.current.stage.addChildAt(t,0);
    }


    function new()
    {
        super();
   
        toolbar = new ToolBar();
        canvas = new Canvas();
        infobox = new InfoBox();

        layer = new map.TileLayer(new OpenStreetMapService(7), 8);
        layer.alpha = 0.15;

        toolbar.move(0, 0);
        canvas.move(0, 0);
        infobox.move(0, 30);
        canvas.setCenter(new LngLat(15.5,49.5));
        canvas.addLayer(new WMSLayer(null, infobox));
        canvas.addLayer(layer);
        stageResized(null);

        initToolbar();

        addChild(canvas);
        addChild(toolbar);
        addChild(infobox);

        canvas.initialize();
        canvas.addEventListener(MapEvent.MAP_MOUSEMOVE, mouseMove);

    }

    public function stageResized(e:Event)
    {
        toolbar.setSize(flash.Lib.current.stage.stageWidth, 30);
        infobox.setSize(300, flash.Lib.current.stage.stageHeight - 30);
        canvas.setSize(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
    }

    function initToolbar()
    {
        var me = this;
        toolbar.addButton(new ZoomOutButton(), "Zoom Out", function(b:CustomButton) { me.canvas.zoomOut(); });
        toolbar.addButton(new ZoomInButton(), "Zoom In",  function(b:CustomButton) { me.canvas.zoomIn(); });
        toolbar.addSeparator(30);
        //pan buttons
        toolbar.addButton(new UpButton(), "Move up",  function(b:CustomButton) { me.pan(1); });
        toolbar.addButton(new DownButton(), "Move down",  function(b:CustomButton) { me.pan(2); });
        toolbar.addButton(new LeftButton(), "Move left",  function(b:CustomButton) { me.pan(4); });
        toolbar.addButton(new RightButton(), "Move right",  function(b:CustomButton) { me.pan(8); });
        toolbar.addSeparator(30);
        //show/hide layer
        toolbar.addButton(new MaximizeButton(), "Show/hide tile layer",  function(b:CustomButton) { 
                          if (me.canvas.layerEnabled(me.layer)) 
                              me.canvas.disableLayer(me.layer);
                          else
                              me.canvas.enableLayer(me.layer);
                          });
    }

    function pan(direction:Int)
    {
       var lt:LngLat = canvas.getLeftTopCorner();
       var br:LngLat = canvas.getRightBottomCorner();
       var p:LngLat  = canvas.getCenter();

       if (direction & 0x3 == 1) p.lat = lt.lat; //up
       if (direction & 0x3 == 2) p.lat = br.lat; //down
       if (direction & 0xC == 4) p.lng = lt.lng; //left
       if (direction & 0xC == 8) p.lng = br.lng; //right

       canvas.panTo(p);
    }

    function mouseMove(e:map.MapEvent)
    {
       toolbar.setText("longitude:" + LngLat.fmtCoordinate(e.point.lng) + 
                       " latitude:" + LngLat.fmtCoordinate(e.point.lat) + 
                       " zoom:" + canvas.getZoom());
    }

}

import flash.display.Loader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.geom.Point;
import flash.utils.Timer;
import flash.events.TimerEvent;
import map.Layer;

class WMSLoader extends Loader
{
    public var offset:Point;
    public var zoom:Int; 
    public var tf:flash.text.TextField;
}

class WMSLayer extends Layer
{
    static var WMSURL:String = "http://wms.jpl.nasa.gov/wms.cgi";

    var ftimer:Timer;
    var infobox:InfoBox;

    public function new(map_service:MapService = null, infobox:InfoBox)
    { 
        super(map_service, false);

        this.infobox = infobox;
        ftimer = new Timer(1000, 1);
        ftimer.addEventListener(TimerEvent.TIMER_COMPLETE, loadImage);
    }

    override function updateContent(forceUpdate:Bool=false)
    {
        if (ftimer.running)
           ftimer.stop();
        ftimer.start();
    }

    override function zoomChanged(prevEnabled:Bool, newZoom:Int)
    {
        super.zoomChanged(prevEnabled, newZoom);

        //remove all images
        while (numChildren > 0) removeChildAt(0);
    }

    function loadImage(e:TimerEvent)
    {
        var loader : WMSLoader = new WMSLoader();
        try 
        {
            loader.offset = getOffset();
            loader.zoom = this.zoom;
            loader.tf = this.infobox.addItem("Loading, please wait ... " + getOffset()); 
            loader.load(getWMSRequest("worldwind_dem"),  new flash.system.LoaderContext(true));
            loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, loaderComplete);
            loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, 
                                                      function(evt) { trace("IO Error"); });

        } 
        catch (unknown : Dynamic)  
        {
            trace("load except:"+unknown);
        }

    }

    function getWMSRequest(layers:String, styles:String = ""): URLRequest
    {
        var lt:LngLat = getLeftTopCorner();
        var rb:LngLat = getRightBottomCorner();

        var request:URLRequest = new URLRequest(WMSURL);
        request.method = flash.net.URLRequestMethod.GET;
        request.data = new URLVariables();
        request.data.Service = "WMS";
        request.data.Request = "GetMap";
        request.data.Version = "1.1.1";
        request.data.Format = "image/png";
        request.data.SRS = "EPSG:4326";
        request.data.BBox = lt.lng+","+rb.lat+","+rb.lng+","+lt.lat;
        request.data.Layers = layers;
        request.data.Width = bbox.width;
        request.data.Height = bbox.height;
        request.data.styles = styles;

        return request;
    }

    function loaderComplete(e:Event)
    { 

        if ((e.target == null) || (e.target.loader == null) || (e.target.loader.content == null))
           return;
 
        var loader:WMSLoader = e.target.loader;

        loader.tf.text = "";

        if (loader.zoom != this.zoom) return;

        loader.tf.text = "Image loaded";

        //append image
        loader.content.x = (-2*loader.offset.x - loader.content.width) / 2.0;
        loader.content.y = (-2*loader.offset.y - loader.content.height) / 2.0;
        this.addChild(loader.content);
    }
}
