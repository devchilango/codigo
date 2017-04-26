//
//  MapaController.swift
//  Pulpo
//
//  Created by Eduardo Guerrero on 21/04/17.
//  Copyright © 2017 Eduardo Guerrero. All rights reserved.
//

import UIKit
import MapKit
import UserNotifications

class MapaController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    var geoUsuario:Bool = false
    var busquedaActiva:Bool = false
    var textIniciar = "Confirmar punto objetivo"
    var textTerminar = "Terminar"
    
    var zonaActiva:zona? = nil
    var centro:CLLocationCoordinate2D? = nil
    
    let locationManager = CLLocationManager()
    
    var zonas:[zona] = []
    let radios:[ (Double, Double) ] = [ (0,10), (11, 50), (51, 100), (101, 200), (201, 6371000) ]
    let mensajes:[ String ] = ["Estás en el punto objetivo", "Estás muy próximo al punto objetivo", "Estás próximo al punto objetivo", "Estás lejos del punto objetivo", "Estás muy lejos del punto objetivo"]
    
    var ultimaUbicacionConocida:CLLocation? = nil
    
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
        vista.placeholder = "Colonia, Calle y cp"
        vista.backgroundColor = UIColor.white
        vista.returnKeyType = .done
        
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
        vista.font = UIFont(name: "Arial", size: 20)
        return vista
    }()
    
    let lbMensaje:UILabel = {
        let vista = UILabel()
        vista.translatesAutoresizingMaskIntoConstraints  = false
        vista.textAlignment = .center
        vista.isHidden = true
        return vista
    }()
    
    let marker:UIImageView = {
        let vista = UIImageView()
        vista.image = UIImage(named: "marker")
        vista.translatesAutoresizingMaskIntoConstraints = false
        return vista
    }()
    
    let centrarMapa:UIButton = {
        let vista = UIButton()
        let imagen = UIImage(named: "centrar")?.withRenderingMode( .alwaysTemplate )
        vista.translatesAutoresizingMaskIntoConstraints = false
        vista.setImage(imagen, for: .normal)
        vista.tintColor = UIColor.blue
        vista.imageView?.contentMode = .scaleAspectFill
        vista.contentMode = .scaleAspectFill
        vista.backgroundColor = UIColor.white
        vista.layer.borderWidth = 1
        vista.layer.borderColor = UIColor.lightGray.cgColor
        vista.layer.cornerRadius = 5
        return vista
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpVista()
        
        generarZonas()
        
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
    }
    
    func generarZonas(){
        
        
        for (index, elem) in self.radios.enumerated(){
            
            let tweet = ( index == 0 ) ? true : false
            let radio:Double = elem.1
            let nuevaZona = zona(index: index, radio: Double(radio), rangoInicio: elem.0, rangoFin:elem.1, activa: false, publicarTweet: tweet, mensaje: mensajes[index])
            zonas.append( nuevaZona )
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let ubicacion = locations.last{
            
            let intervalo = ubicacion.timestamp.timeIntervalSinceNow
            if abs(intervalo) > 1{
                return
            }
            
            ultimaUbicacionConocida = ubicacion
        }
        
        
        if let ubicacion = locations.last{
            if !geoUsuario{
                let centro = CLLocationCoordinate2D(latitude: ubicacion.coordinate.latitude, longitude: ubicacion.coordinate.longitude)
                let region = MKCoordinateRegion(center: centro, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005 ))
                mapa.setRegion(region, animated: true)
                geoUsuario = true
                self.locationManager.stopUpdatingLocation()
            }

        }
        
        if busquedaActiva{
            if let ubicacion = locations.last{
                
                if centro == nil{
                    centro = mapa.centerCoordinate
                }
                
                
                if let punto = centro{
                    let ubicacionUsuario = CLLocation(latitude: ubicacion.coordinate.latitude, longitude: ubicacion.coordinate.longitude)
                    let puntoObjetivo = CLLocation(latitude: punto.latitude, longitude: punto.longitude)
                    
                    
                    let distancia = puntoObjetivo.distance(from: ubicacionUsuario)
                    lbDistancia.text = String( format: "Distancia %2.2f m  ",distancia )
                    
                    for ( index, elem ) in zonas.enumerated(){
                        if  distancia >= elem.rangoInicio && distancia <= elem.rangoFin{
                            if !elem.activa{
                                
                                lbMensaje.text = mensajes[index]
                                
                                for (index, _) in zonas.enumerated(){
                                    zonas[ index ].activa = false
                                }

                                zonas[index].activa = true
                                zonaActiva = elem
                                
                                if elem.publicarTweet{
                                    publicarTweet()
                                }
                                
                                enviarNotificacion()
                                
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    func enviarNotificacion(){
        
        let status = UIApplication.shared.applicationState
        
        
        if let zona = zonaActiva{
            if status == .active{
                
                let alertController = UIAlertController(title: "Notificacion", message: zona.mensaje, preferredStyle: .alert)
                let ok = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                alertController.addAction( ok )
                
                self.present(alertController, animated: true, completion: nil)
                
            }else if status == .background{
                let notification = UILocalNotification()
                notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.alertBody = zona.mensaje
                notification.alertAction = "open"
                notification.hasAction = true
                UIApplication.shared.scheduleLocalNotification(notification)
            }
        }
    }
    
    
    func publicarTweet(){
        
        if let coordenadas = centro{
            
            let direccion = "http://tazitasmagicas.com/pulpo/tweet.php?latitud=\(coordenadas.latitude)&longitud=\(coordenadas.longitude)"
            let url = URL(string: direccion)
            
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            }
            
            task.resume()
        }
        
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
        
        for (_, item) in radios.enumerated(){
            let radio = item.1
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
        lbMensaje.isHidden = false
        self.locationManager.startUpdatingLocation()
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
        lbMensaje.isHidden = true
        self.locationManager.stopUpdatingLocation();
        
        for (index, _) in zonas.enumerated(){
            zonas[index].activa = false
        }
        
        centro = nil
        txtBusqueda.text = ""
    }
    
    func setUpVista(){

        self.view.addSubview( mapa )
        self.view.addSubview( fondoBusqueda )
        self.view.addSubview( txtBusqueda )
        self.view.addSubview( btnBuscarDireccion )
        self.view.addSubview( btnConfirmar )
        self.view.addSubview( marker )
        self.view.addSubview( lbDistancia )
        self.view.addSubview( lbMensaje )
        self.view.addSubview( centrarMapa )
        
        txtBusqueda.delegate = self
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
        view.addConstraint( NSLayoutConstraint(item: lbDistancia, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 16 ))
        
        view.addConstraint( NSLayoutConstraint(item: lbMensaje, attribute: .top, relatedBy: .equal, toItem: lbDistancia, attribute: .bottom, multiplier: 1, constant: 1 ))
        view.addConstraint( NSLayoutConstraint(item: lbMensaje, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0 ))
        
        view.addConstraint( NSLayoutConstraint(item: centrarMapa, attribute: .bottom, relatedBy: .equal, toItem: btnConfirmar , attribute: .top, multiplier: 1, constant: -5 ))
        view.addConstraint( NSLayoutConstraint(item: centrarMapa, attribute: .right, relatedBy: .equal, toItem: btnConfirmar , attribute: .right, multiplier: 1, constant: 0 ))
        view.addConstraint( NSLayoutConstraint(item: centrarMapa, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40) )
        view.addConstraint( NSLayoutConstraint(item: centrarMapa, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40) )
        
        btnConfirmar.addTarget(self, action: #selector( MapaController.gestionarBusqueda ), for: .touchUpInside )
        btnBuscarDireccion.addTarget(self, action: #selector( MapaController.buscarDirecciones ), for: .touchUpInside)
        
        centrarMapa.addTarget(self, action: #selector( MapaController.centrarPosicion), for: .touchUpInside)
        
        
    }
    
    func centrarPosicion(){
        
        
        if let ubicacion = ultimaUbicacionConocida{
            let centro = CLLocationCoordinate2D(latitude: ubicacion.coordinate.latitude, longitude: ubicacion.coordinate.longitude)
            mapa.setCenter(centro, animated: true)
        }
        
    }
    
    func buscarDirecciones(){
        
        let direccion = txtBusqueda.text
        let geocoder = CLGeocoder()
        
        if let dir = direccion{
            
            if direccion != ""{
                geocoder.geocodeAddressString(dir) { (placemarks, error) in
                    if let ubicacion = placemarks{
                        if let coordenadas = ubicacion.first?.location{
                            let centro = CLLocationCoordinate2D(latitude: coordenadas.coordinate.latitude, longitude: coordenadas.coordinate.longitude)
                            self.mapa.setCenter( centro, animated: true)
                            
                            self.txtBusqueda.resignFirstResponder()
                            
                        }
                    }else{
                        let alerta = UIAlertController(title: "Alerta", message: "Sea mas especifico en su busqueda, escriba la Colonia, calle y codigo postal", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                        alerta.addAction(ok)
                        self.present(alerta, animated: true, completion: nil)
                    }
                }
            }else{
                let alerta = UIAlertController(title: "Alerta", message: "Escriba una direccion", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                alerta.addAction(ok)
                self.present(alerta, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circulo = MKCircleRenderer(overlay: overlay)
        circulo.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circulo.strokeColor = UIColor.blue
        circulo.lineWidth = 1
        return circulo
    }    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
