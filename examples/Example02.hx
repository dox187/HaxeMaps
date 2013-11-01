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
import flash.display.StageDisplayState;
import flash.events.Event;
import map.Canvas;
import map.LngLat;
import map.TileLayer;
import map.MapService;
import com.Button;
import com.ToolBar;

class Example02 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example02 = new Example02();
       flash.Lib.current.stage.addEventListener(Event.RESIZE, t.stageResized);
       flash.Lib.current.stage.addChildAt(t,0);
    }


    function new()
    {
        super();
   
        toolbar = new ToolBar();
        toolbar.move(0, 0);
        canvas = new Canvas();
        canvas.move(0, 0);

        stageResized(null); //update toolbar & canvas size

        canvas.setZoom(3);
        canvas.setCenter(new LngLat(16.124, 49.124));
        canvas.addLayer(new TileLayer(new OpenStreetMapService(), 8, #if TILE_OPT false #else true #end));
        canvas.initialize();
        canvas.addEventListener(MapEvent.MAP_MOUSEMOVE, mouseMove);

        initToolbar();

        addChild(canvas);
        addChild(toolbar);
    }

    public function stageResized(e:Event)
    {
        toolbar.setSize(flash.Lib.current.stage.stageWidth, 30);
        canvas.setSize(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
    }

    function initToolbar()
    {
        var me = this;
        toolbar.addButton(new MaximizeButton(), "Toggle full screen mode", function(b:CustomButton) { 
                          if (flash.Lib.current.stage.displayState == StageDisplayState.FULL_SCREEN) 
                             flash.Lib.current.stage.displayState = StageDisplayState.NORMAL;
                          else 
                             flash.Lib.current.stage.displayState = StageDisplayState.FULL_SCREEN;
                         });
        toolbar.addSeparator();
        //zoom out button
        toolbar.addButton(new ZoomOutButton(), "Zoom Out", function(b:CustomButton) { me.canvas.zoomOut(); });
        //zoom level buttons
        var z = canvas.getMinZoom();
        var zmax = canvas.getMaxZoom();
        while (z <= zmax) 
        {
           var zoom = z;
           toolbar.addButton(new BarButton(0), "Set zoom to " + Std.string(z),  
                             function(b:CustomButton) { me.canvas.setZoom(zoom); }, -10
                            );
           z += 1;
        }
        //zoom in button
        toolbar.addButton(new ZoomInButton(), "Zoom In",  function(b:CustomButton) { me.canvas.zoomIn(); });
        toolbar.addSeparator(30);
        //pan buttons
        toolbar.addButton(new UpButton(), "Move up",  function(b:CustomButton) { me.pan(1); });
        toolbar.addButton(new DownButton(), "Move down",  function(b:CustomButton) { me.pan(2); });
        toolbar.addButton(new LeftButton(), "Move left",  function(b:CustomButton) { me.pan(4); });
        toolbar.addButton(new RightButton(), "Move right",  function(b:CustomButton) { me.pan(8); });
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
