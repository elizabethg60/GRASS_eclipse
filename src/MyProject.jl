module MyProject 

using Distributed
using SPICE
using Downloads: download
using LinearAlgebra
using NaNMath
using Statistics
using JLD2
using Test
using ThreadsX

include("get_kernels.jl")
include("epoch_computations.jl")
include("epoch_computations_pa.jl")
include("coordinates.jl")
include("coordinates_pa.jl")
include("velocity.jl")
include("velocity_pa.jl")
include("moon.jl")
include("time_loop.jl")
include("parallel_v2.jl")

#set required body paramters as global variables 
#E,S,M radii (units:km)
earth_radius = bodvrd("EARTH", "RADII")[1]	
sun_radius = bodvrd("SUN","RADII")[1]
earth_radius_pole = bodvrd("EARTH", "RADII")[3]	
moon_radius = bodvrd("MOON", "RADII")[1] 

reiners_timestamps = ["2015-03-20T7:07:57", "2015-03-20T7:09:45", "2015-03-20T7:11:34", "2015-03-20T7:13:22", "2015-03-20T7:15:11", "2015-03-20T7:17:00", "2015-03-20T7:18:49", "2015-03-20T7:20:38", "2015-03-20T7:22:27", "2015-03-20T7:24:16", "2015-03-20T7:26:05", "2015-03-20T7:27:53", "2015-03-20T7:29:42", "2015-03-20T7:31:30", "2015-03-20T7:33:19", "2015-03-20T7:35:09", "2015-03-20T7:36:58", "2015-03-20T7:38:46", "2015-03-20T7:40:34", "2015-03-20T7:42:22", "2015-03-20T7:44:11", "2015-03-20T7:46:00", "2015-03-20T7:47:48", "2015-03-20T7:49:37", "2015-03-20T7:51:25", "2015-03-20T7:53:13", "2015-03-20T7:55:02", "2015-03-20T7:56:50", "2015-03-20T7:58:39", "2015-03-20T8:00:27", "2015-03-20T8:02:15", "2015-03-20T8:04:04", "2015-03-20T8:05:53", "2015-03-20T8:07:41", "2015-03-20T8:09:30", "2015-03-20T8:11:18", "2015-03-20T8:13:07", "2015-03-20T8:14:55", "2015-03-20T8:16:43", "2015-03-20T8:18:32", "2015-03-20T8:20:20", "2015-03-20T8:22:09", "2015-03-20T8:23:57", "2015-03-20T8:25:46", "2015-03-20T8:27:34", "2015-03-20T8:29:23", "2015-03-20T8:31:11", "2015-03-20T8:32:59", "2015-03-20T8:34:47", "2015-03-20T8:36:36", "2015-03-20T8:38:54", "2015-03-20T8:40:43", "2015-03-20T8:42:31", "2015-03-20T8:44:19", "2015-03-20T8:46:08", "2015-03-20T8:47:56", "2015-03-20T8:49:45", "2015-03-20T8:51:34", "2015-03-20T8:53:22", "2015-03-20T8:55:11", "2015-03-20T8:56:59", "2015-03-20T8:58:47", "2015-03-20T9:00:36", "2015-03-20T9:02:24", "2015-03-20T9:04:13", "2015-03-20T9:06:01", "2015-03-20T9:07:50", "2015-03-20T9:09:38", "2015-03-20T9:11:27", "2015-03-20T9:13:15", "2015-03-20T9:15:04", "2015-03-20T9:16:53", "2015-03-20T9:18:42", "2015-03-20T9:20:30", "2015-03-20T9:22:19", "2015-03-20T9:24:08", "2015-03-20T9:25:57", "2015-03-20T9:27:45", "2015-03-20T9:29:34", "2015-03-20T9:31:23", "2015-03-20T9:33:11", "2015-03-20T9:34:59", "2015-03-20T9:36:48", "2015-03-20T9:38:37", "2015-03-20T9:40:26", "2015-03-20T9:42:15", "2015-03-20T9:44:03", "2015-03-20T9:45:52", "2015-03-20T9:47:40", "2015-03-20T9:49:29", "2015-03-20T9:51:18", "2015-03-20T9:53:07", "2015-03-20T9:54:55", "2015-03-20T9:56:44", "2015-03-20T9:58:33", "2015-03-20T10:00:21", "2015-03-20T10:02:10", "2015-03-20T10:03:58", "2015-03-20T10:05:47", "2015-03-20T10:07:36", "2015-03-20T10:09:54", "2015-03-20T10:11:43", "2015-03-20T10:13:33", "2015-03-20T10:15:22", "2015-03-20T10:17:11", "2015-03-20T10:19:00", "2015-03-20T10:20:49", "2015-03-20T10:22:38", "2015-03-20T10:24:27", "2015-03-20T10:26:17", "2015-03-20T10:28:07", "2015-03-20T10:29:56", "2015-03-20T10:31:45", "2015-03-20T10:33:34", "2015-03-20T10:35:22", "2015-03-20T10:37:12", "2015-03-20T10:39:01", "2015-03-20T10:40:49", "2015-03-20T10:42:38", "2015-03-20T10:44:27", "2015-03-20T10:46:16", "2015-03-20T10:48:05", "2015-03-20T10:49:54", "2015-03-20T10:51:43", "2015-03-20T10:53:32", "2015-03-20T10:55:21", "2015-03-20T10:57:10", "2015-03-20T10:58:59", "2015-03-20T11:00:49", "2015-03-20T11:02:38", "2015-03-20T11:04:27", "2015-03-20T11:06:16", "2015-03-20T11:08:05", "2015-03-20T11:09:54", "2015-03-20T11:11:43", "2015-03-20T11:13:33", "2015-03-20T11:15:22", "2015-03-20T11:17:10", "2015-03-20T11:18:59", "2015-03-20T11:20:48", "2015-03-20T11:22:37", "2015-03-20T11:24:26", "2015-03-20T11:26:15", "2015-03-20T11:28:04", "2015-03-20T11:29:53", "2015-03-20T11:31:41", "2015-03-20T11:33:30", "2015-03-20T11:35:19", "2015-03-20T11:37:07", "2015-03-20T11:38:56", "2015-03-20T11:48:37", "2015-03-20T11:50:26", "2015-03-20T11:52:15", "2015-03-20T11:54:04", "2015-03-20T11:55:53", "2015-03-20T11:57:41", "2015-03-20T11:59:30", "2015-03-20T12:01:19", "2015-03-20T12:03:07"]
neid_timestamps = ["2023-10-14T15:26:18", "2023-10-14T15:27:40", "2023-10-14T15:29:03", "2023-10-14T15:30:26", "2023-10-14T15:31:48", "2023-10-14T15:33:11", "2023-10-14T15:34:34", "2023-10-14T15:35:56", "2023-10-14T15:37:19", "2023-10-14T15:38:42", "2023-10-14T15:40:04", "2023-10-14T15:41:27", "2023-10-14T15:42:50", "2023-10-14T15:44:12", "2023-10-14T15:45:35", "2023-10-14T15:46:58", "2023-10-14T15:48:20", "2023-10-14T15:49:43", "2023-10-14T15:51:06", "2023-10-14T15:52:29", "2023-10-14T15:53:51", "2023-10-14T15:55:14", "2023-10-14T15:56:37", "2023-10-14T15:57:59", "2023-10-14T15:59:22", "2023-10-14T16:00:45", "2023-10-14T16:02:07", "2023-10-14T16:03:30", "2023-10-14T16:04:53", "2023-10-14T16:06:15", "2023-10-14T16:07:38", "2023-10-14T16:09:01", "2023-10-14T16:10:23", "2023-10-14T16:11:46", "2023-10-14T16:13:09", "2023-10-14T16:14:31", "2023-10-14T16:15:54", "2023-10-14T16:17:17", "2023-10-14T16:18:39", "2023-10-14T16:20:02", "2023-10-14T16:21:25", "2023-10-14T16:22:48", "2023-10-14T16:24:10", "2023-10-14T16:25:33", "2023-10-14T16:26:56", "2023-10-14T16:28:18", "2023-10-14T16:29:41", "2023-10-14T16:31:04", "2023-10-14T16:32:26", "2023-10-14T16:33:49", "2023-10-14T16:35:12", "2023-10-14T16:36:34", "2023-10-14T16:37:57", "2023-10-14T16:39:20", "2023-10-14T16:40:42", "2023-10-14T16:42:05", "2023-10-14T16:43:28", "2023-10-14T16:44:50", "2023-10-14T16:46:13", "2023-10-14T16:47:36", "2023-10-14T16:48:58", "2023-10-14T16:50:21", "2023-10-14T16:51:44", "2023-10-14T16:53:06", "2023-10-14T16:54:29", "2023-10-14T16:55:52", "2023-10-14T16:57:15", "2023-10-14T16:58:37", "2023-10-14T17:00:00", "2023-10-14T17:01:23", "2023-10-14T17:02:45", "2023-10-14T17:04:08", "2023-10-14T17:05:31", "2023-10-14T17:06:53", "2023-10-14T17:08:16", "2023-10-14T17:09:39", "2023-10-14T17:11:01", "2023-10-14T17:12:24", "2023-10-14T17:13:47", "2023-10-14T17:15:09", "2023-10-14T17:16:32", "2023-10-14T17:17:55", "2023-10-14T17:19:17", "2023-10-14T17:20:40", "2023-10-14T17:22:03", "2023-10-14T17:23:25", "2023-10-14T17:24:48", "2023-10-14T17:26:11", "2023-10-14T17:27:34", "2023-10-14T17:28:56", "2023-10-14T17:30:19", "2023-10-14T17:31:42", "2023-10-14T17:33:04", "2023-10-14T17:34:27", "2023-10-14T17:35:50", "2023-10-14T17:37:12", "2023-10-14T17:38:35", "2023-10-14T17:39:58", "2023-10-14T17:41:20", "2023-10-14T17:42:43", "2023-10-14T17:44:06", "2023-10-14T17:45:28", "2023-10-14T17:46:51", "2023-10-14T17:48:14", "2023-10-14T17:49:36", "2023-10-14T17:50:59", "2023-10-14T17:52:22", "2023-10-14T17:53:44", "2023-10-14T17:55:07", "2023-10-14T17:56:30", "2023-10-14T17:57:53", "2023-10-14T17:59:15", "2023-10-14T18:00:38", "2023-10-14T18:02:01", "2023-10-14T18:03:23", "2023-10-14T18:04:46", "2023-10-14T18:06:09", "2023-10-14T18:07:31", "2023-10-14T18:08:54", "2023-10-14T18:10:17", "2023-10-14T18:11:39", "2023-10-14T18:13:02", "2023-10-14T18:14:25", "2023-10-14T18:15:47", "2023-10-14T18:17:10", "2023-10-14T18:18:33", "2023-10-14T18:19:55", "2023-10-14T18:21:18", "2023-10-14T18:22:41", "2023-10-14T18:24:03", "2023-10-14T18:25:26", "2023-10-14T18:26:49", "2023-10-14T18:28:11", "2023-10-14T18:29:34", "2023-10-14T18:30:57", "2023-10-14T18:32:20", "2023-10-14T18:33:42", "2023-10-14T18:35:05", "2023-10-14T18:36:28", "2023-10-14T18:37:50", "2023-10-14T18:39:13", "2023-10-14T18:40:36", "2023-10-14T18:41:58", "2023-10-14T18:43:21", "2023-10-14T18:44:44", "2023-10-14T18:46:06", "2023-10-14T18:47:29", "2023-10-14T18:48:52", "2023-10-14T18:50:14", "2023-10-14T18:51:37", "2023-10-14T18:53:00", "2023-10-14T18:54:22", "2023-10-14T18:55:45", "2023-10-14T18:57:08", "2023-10-14T18:58:30", "2023-10-14T18:59:53", "2023-10-14T19:01:16", "2023-10-14T19:02:39"]

include("test/runtests.jl")

end #module