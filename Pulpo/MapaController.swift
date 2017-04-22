//
//  MapaController.swift
//  Pulpo
//
//  Created by Eduardo Guerrero on 21/04/17.
//  Copyright © 2017 Eduardo Guerrero. All rights reserved.
//

import UIKit
import MapKit

class MapaController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var geoUsuario:Bool = false
    var busquedaActiva:Bool = false
    var textIniciar = "Confirmar punto objetivo"
    var textTerminar = "Terminar"
    
    let radios = [10, 50, 100, 200]
    
    let locationManager = CLLocationManager()
    
    let mapa:MKMapView = {
        let vista = MKMapView()
        vista.frame = UIScreen.main.bounds
        vista.mapType = .standard
        vista.isZoomEnabled = true
        vista.isScrollEnabled = true
        vista.showsUserLocation = true
        
        return vista
    }()
    
    let txtBusqueda:UITextField = {
        let vista = UITextField()
        vista.translatesAutoresizingMaskIntoConstraints = false
        vista.borderStyle = .line
        vista.placeholder = "Escriba una direccion"
        vista.backgroundColor = UIColor.white
        
        return vista
    }()
    
    let btnBuscarDireccion:UIButton = {
        let vista = UIButton()
        vista.translatesAutoresizingMaskIntoConstraints = false
        vista.setTitle("Buscar", for: UIControlState())
        vista.setTitleColor( UIColor.white , for: UIControlState())
        vista.layer.borderColor = UIColor.gray.cgColor
        vista.layer.cornerRadius = 4
        vista.layer.borderWidth = 1
        vista.backgroundColor = UIColor.blue
        
        return vista
    }()
    
    let fondoBusqueda:UIView = {
        let vista = UIView()
        vista.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80)
        vista.backgroundColor = UIColor.white
        vista.alpha = 0.7
        vista.layer.borderColor = UIColor.lightGray.cgColor
        vista.layer.borderWidth = 1
        return vista
    }()
    
    let btnConfirmar:UIButton = {
        let vista = UIButton()
        vista.translatesAutoresizingMaskIntoConstraints = false
        vista.setTitleColor( UIColor.black , for: UIControlState())
        vista.layer.borderColor = UIColor.gray.cgColor
        vista.layer.cornerRadius = 4
        vista.layer.borderWidth = 1
        vista.backgroundColor = UIColor.green
        
        return vista
    }()
    
    let lbDistancia:UILabel = {
        let vista = UILabel()
        vista.translatesAutoresizingMaskIntoConstraints = false
        vista.text = "Distancia 10 m"
        vista.isHidden = true
        vista.textAlignment = .center
        vista.font = UIFont(name: "Arial", size: 25)
        return vista
    }()
    
    let marker:UIImageView = {
        let vista = UIImageView()
        vista.image = UIImage(named: "marker")
        vista.translatesAutoresizingMaskIntoConstraints = false
        return vista
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpVista()
        
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let ubicacion = locations.last{
            if !geoUsuario{
                let centro = CLLocationCoordinate2D(latitude: ubicacion.coordinate.latitude, longitude: ubicacion.coordinate.longitude)
                let region = MKCoordinateRegion(center: centro, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005 ))
                mapa.setRegion(region, animated: true)
                geoUsuario = true
            }

        }
        
        
    }
    
    
    func region( _ centro:CLLocationCoordinate2D, radio:Int ) -> CLCircularRegion {
        
        let centro = CLLocationCoordinate2D(latitude: centro.latitude, longitude: centro.longitude)
        let radio:CLLocationDistance = 10000
        let region = CLCircularRegion(center: centro, radius: radio, identifier: "Region")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        return region
    }
    
    func gestionarBusqueda(){
        
        if !busquedaActiva{
            iniciarBusqueda()
        }else{
            terminarBusqueda()
        }
        
    }
    
    func iniciarBusqueda(){
        
        let centro = mapa.centerCoordinate
        
        for (index, item) in radios.enumerated(){
            let radio = item
            let nuevaRegion = region( centro, radio: radio )
            
            let circulo = MKCircle(center: centro, radius: CLLocationDistance(radio) )
            mapa.add(circulo)
            
        }
        
        
        btnConfirmar.setTitle(textTerminar, for: UIControlState())
        btnConfirmar.setTitleColor(UIColor.white, for: UIControlState())
        btnConfirmar.backgroundColor = UIColor.red
        txtBusqueda.isHidden = true
        btnBuscarDireccion.isHidden = true
        marker.isHidden = true
        busquedaActiva = true
        lbDistancia.isHidden = false
    }
    
    
    
    func terminarBusqueda(){
        
        mapa.removeOverlays( mapa.overlays )
        btnConfirmar.setTitle(textIniciar, for: UIControlState())
        btnConfirmar.setTitleColor(UIColor.black, for: UIControlState())
        btnConfirmar.backgroundColor = UIColor.green
        txtBusqueda.isHidden = false
        btnBuscarDireccion.isHidden = false
        marker.isHidden = false
        busquedaActiva = false
        lbDistancia.isHidden = true
    }
    
    func setUpVista(){

        self.view.addSubview( mapa )
        self.view.addSubview( fondoBusqueda )
        self.view.addSubview( txtBusqueda )
        self.view.addSubview( btnBuscarDireccion )
        self.view.addSubview( btnConfirmar )
        self.view.addSubview( marker )
        self.view.addSubview( lbDistancia )
        
        mapa.delegate = self
        locationManager.delegate = self
        btnConfirmar.setTitle( textIniciar, for: UIControlState())
        
        view.addConstraint( NSLayoutConstraint(item: txtBusqueda, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 32 ))
        view.addConstraint( NSLayoutConstraint(item: btnBuscarDireccion, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 32 ))

        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[txt]-16-[btn(100)]-16-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["txt":txtBusqueda, "btn": btnBuscarDireccion]  ))
        
        view.addConstraints( NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[btn]-16-|", options: NSLayoutFormatOptions(), metrics: nil, views: [ "btn": btnConfirmar ] ) )
        view.addConstraint( NSLayoutConstraint(item: btnConfirmar, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -40 ))
        
        view.addConstraint(NSLayoutConstraint(item: marker, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint( NSLayoutConstraint(item: marker, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant:-40 ))
        
        view.addConstraint( NSLayoutConstraint(item: lbDistancia, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0 ))
        view.addConstraint( NSLayoutConstraint(item: lbDistancia, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 32 ))
        
        btnConfirmar.addTarget(self, action: #selector( MapaController.gestionarBusqueda ), for: .touchUpInside )
        
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circleRenderer.strokeColor = UIColor.blue
        circleRenderer.lineWidth = 1
        return circleRenderer
    }    

}
