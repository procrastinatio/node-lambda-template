'use strict';


var request = require('request');
var async = require('async');
var tokml = require('tokml');
var reproj = require('reproject');
var proj4 = require('proj4');
var qs = require('qs');

var lv03WDefn = '+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 +k_0=1 +x_0=600000 +y_0=200000 +ellps=bessel +towgs84=674.4,15.1,405.3,0,0,0,0 +units=m +no_defs',
    lv95Defn = '+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 +k_0=1 +x_0=2600000 +y_0=1200000 +ellps=bessel +towgs84=674.374,15.056,405.346,0,0,0,0 +units=m +no_defs',
    lv03 = proj4.Proj(lv03WDefn),
    lv95 = proj4.Proj(lv95Defn),
    crss = {
        'EPSG:21781': lv03,
        'EPSG:2056': lv95,

    };


    
///rest/services/api/MapServer/find?layer=ch.bafu.bundesinventare-bln&searchText=wald&searchField=bln_name&returnGeometry=false';

//var url = 'http://api3.geo.admin.ch/rest/services/api/MapServer/identify?geometryType=esriGeometryEnvelope&geometry=600000,125000,650000,175000&imageDisplay=500,500,96&mapExtent=600000,125000,650000,175000&tolerance=1&layers=all:ch.bafu.bundesinventare-bln&geometryFormat=geojson


function convert2KML(data, callback) {

    var empty = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';

    var kml = tokml(data, {
        documentName: 'My List Of Markers',
        documentDescription: 'One of the many places you are not I am',
    });

    if (kml == empty) {
        return callback(new Error('An error has occured'));
    }

    callback(null, kml);
}

exports.handler = function(event, context) {
    var base_url = event.url || 'https://mf-chsdi.dev.bgdi.ch';
    var path = event.path || '/rest/services/api/MapServer/identify';
    var unencoded = qs.stringify(event.params, { encode: false });
    var url = base_url  + path +"?" +  unencoded;
    
    
    console.log(url);


    async.waterfall([
        function download(next) {
            request(url, function(err, resp, data) {

                if (resp.statusCode !== 200) {
                    throw resp.statusCode;
                };

                var records = JSON.parse(data).results;

                var features = [];

                var item = records[Math.floor(Math.random() * records.length)];

                features.push(reproj.toWgs84(item, lv03));


                var mygeosjons = {
                    type: 'FeatureCollection',
                    features: features,
                };

                next(err, mygeosjons);
            });

        },

        function convert(data, next) {

            convert2KML(data, function(err, kml) {

                next(err, kml);
            });
        },

        function save(data, next) {

            request({
                url:  base_url + '/files', 
                method: 'POST',
                headers: {
                    'Content-Type': 'application/vnd.google-earth.kml+xml',
                    Referer: 'http://map.geo.admin.ch',
                    'Content-Length': data.length,
                },
                body: data
            }, function(error, response, body) {
                if (error) {
                    console.log(error);
                } else {
                    var data = JSON.parse(body);

                    next(error, data);
                }
            });
        },

        function response(data, next) {
            var url = base_url.replace('chsdi3','geoadmin3') + '?adminId=' + data.adminId;
            console.log(url);
            var kml = base_url + "/files/" + data.fileId;
             console.log(kml);
            context.succeed({url: url, kml: kml});
            //context.done();

        },
    ], function(err) {
        if (err) throw err;
    });




};
