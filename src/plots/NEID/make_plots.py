import h5py
import numpy as np
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
mpl = plt.matplotlib 

#rm curve
f = h5py.File("rv_intensity.jld2", "r")
RV_list = f["RV_list"][()]
intensity_list = f["intensity_list"][()]
date_strings = f["timestamps"][()]
fig = plt.figure()
ax1 = fig.add_subplot()
time_stamps = []
for i in date_strings:
    time_stamps.append(datetime.strptime(i, "%Y-%m-%dT%H:%M:%S"))
ax1.scatter(time_stamps, RV_list, label = "Model")
data = pd.read_csv("NEID_Data.csv")
time_stamps_data = []
for i in data["obsdate"]:
    time_stamps_data.append(datetime.strptime(i, "%Y-%m-%d %H:%M:%S"))
ax1.scatter(time_stamps_data[15:-150], data["ccfrvmod"][15:-150]*1000+631, label = "NEID RVs") 
ax1.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
ax1.set_xlabel("Time (UTC)")
ax1.set_ylabel("RV [m/s]")
plt.legend()
plt.savefig("rm_curve.png")
plt.show()
#residuals
fig = plt.figure()
ax1 = fig.add_subplot()
ax1.scatter(time_stamps, (data["ccfrvmod"][15:-150]*1000+631) - RV_list)  
ax1.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
ax1.set_xlabel("Time (UTC)")
ax1.set_ylabel("residuals") 
plt.savefig("residuals.png")
plt.show()

#intensity
fig = plt.figure()
ax1 = fig.add_subplot()
ax1.scatter(time_stamps, intensity_list)  
ax1.xaxis.set_major_formatter(mdates.DateFormatter("%H:%M:%S"))
ax1.set_xlabel("Time (UTC)")
ax1.set_ylabel("Relative Intensity") 
plt.savefig("intensity.png")
plt.show()

#projected solar velocities at each timestamp for eclipse movie
for i in range(1,len(time_stamps)):
    f = h5py.File("data/timestamp_{}.jld2".format(i), "r")
    projected_velocities = f["projected_velocities"][()]
    ra = f["ra"][()]
    dec = f["dec"][()]
    ra_moon = f["ra_moon"][()]
    dec_moon = f["dec_moon"][()]
    mu_grid = f["mu_grid"][()]
    LD_all = f["LD_all"][()]
    date_strings = f["timestamp"][()]

    #projected velocity rotation 
    cnorm = mpl.colors.Normalize(np.min(projected_velocities), np.max(projected_velocities))
    colors = mpl.cm.seismic(cnorm(projected_velocities))
    pcm = plt.pcolormesh(ra, dec, projected_velocities, cmap="seismic",vmin=-2000, vmax=2000)
    cb = plt.colorbar(pcm, norm=cnorm, ax=plt.gca())
    plt.gca().invert_xaxis()
    cb.set_label("projected velocity (m/s)")
    plt.xlabel("RA")
    plt.ylabel("dec")
    plt.savefig("movie/projected_vel_{}.png".format(i))
    plt.clf()