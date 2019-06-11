# Map-based navigation with ArUco markers

> **Info** Marker detection requires the camera module to be correctly plugged in and [configured](camera.md).

<!-- -->

> **Hint** We recommend using our [custom PX4 firmware](firmware.md).

`aruco_map` module detects whole ArUco-based maps. Map-based navigation is possible using vision position estimate (VPE).

## Configuration

In order to enable map detection set `aruco_map` and `aruco_detect` arguments to `true` in `~/catkin_ws/src/clever/clever/launch/aruco.launch`:

```xml
<arg name="aruco_detect" default="true"/>
<arg name="aruco_map" default="true"/>
```

Set `aruco_vpe` to `true` to publish detected camera position to the flight controller as VPE data:

```xml
<arg name="aruco_vpe" default="true"/>
```

## Marker map definition

Map is defined in a text file; each line has the following format:

```
marker_id marker_size x y z z_angle y_angle x_angle
```

`N_angle` is the angle of rotation along the `N` axis in radians.

Map path is defined in the `map` parameter:

```xml
<param name="map" value="$(find aruco_pose)/map/map.txt"/>
```

Some map examples are provided in [`~/catkin_ws/src/clever/aruco_pose/map`](https://github.com/CopterExpress/clever/tree/master/aruco_pose/map).

Grid maps may be generated using the `genmap.py` script:

```bash
rosrun aruco_pose genmap.py length x y dist_x dist_y first > ~/catkin_ws/src/clever/aruco_pose/map/test_map.txt
```

`length` is the size of each marker, `x` is the marker count along the *x* axis, `y` is the marker count along the *y* axis, `dist_x` is the distance between the centers of adjacent markers along the *x* axis, `dist_y` is the distance between the centers of the *y* axis, `first` is the ID of the first marker (bottom left marker, unless `--top-left` is specified), `test_map.txt` is the name of the generated map file. The optional `--top-left` parameter changes the numbering of markers, making the top left marker the first one.

Usage example:

```bash
rosrun aruco_pose genmap.py 0.33 2 4 1 1 0 > ~/catkin_ws/src/clever/aruco_pose/map/test_map.txt
```

### Checking the map

The currently active map is posted in the `/aruco_map/image` ROS topic. It can be viewed using [web_video_server](web_video_server.md) by opening the following link: http://192.168.11.1:8080/snapshot?topic=/aruco_map/image

<img src="../assets/aruco-map.png" width=600>

Current estimated pose (relative to the detected map) is published in the `aruco_map/pose` ROS topic. If the VPE is disabled, the `aruco_map` [TF frame](frames.md) is created; otherwise, the `aruco_map_detected` frame is created instead. Visualization for the current map is also posted in the `aruco_map/visualization` ROS topic; it may be visualized in [rviz](rviz.md).

An easy to understand detected map visualization is posted in the `aruco_map/debug` ROS topic (live view is available on http://192.168.11.1:8080/stream_viewer?topic=/aruco_map/debug):

<img src="../assets/aruco-map-debug.png" width=600>

## Coordinate system

The marker map adheres to the [ROS coordinate system convention](http://www.ros.org/reps/rep-0103.html), using the <abbr title="East-North-Up">ENU</abbr> coordinate system:

* the **<font color=red>x</font>** axis points to the right side of the map;
* the **<font color=green>y</font>** axis points to the top side of the map;
* the **<font color=blue>z</font>** axis points outwards from the plane of the marker

<img src="../assets/aruco-map-axis.png" width="600">

## VPE setup

In order to enable vision position estimation you should use the following [PX4 parameters](px4_parameters.md).

<!-- TODO: Complete translation -->