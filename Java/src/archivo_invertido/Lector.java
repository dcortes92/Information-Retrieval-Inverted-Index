/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package archivo_invertido;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.util.ArrayList;

/**
 *
 * @author SirIsaac
 */
public class Lector {
    
    int N = 0;
    int actual = 1;
    ArrayList<Elemento> Vocabulario_por_Documento = new ArrayList<>();
    ArrayList<ArrayList> Vocabulario =  new ArrayList<>();
    ArrayList<Elemento_General> Vocabulario_general = new ArrayList<>();
    
    public void leer()
    {
        try{            
            String input = "D:\\Vocabulario.txt";
            // Abrimos el archivo
            FileInputStream fstream = new FileInputStream(input);
            // Creamos el objeto de entrada
            DataInputStream entrada = new DataInputStream(fstream);
            // Creamos el Buffer de Lectura
            BufferedReader buffer = new BufferedReader(new InputStreamReader(entrada));
            String strLinea;
            // Leer el archivo linea por linea
            while ((strLinea = buffer.readLine()) != null)   {
                // Imprimimos la línea por pantalla
                String[] elemtos = strLinea.split(";");
                String contenido = elemtos[0];
                int documento = Integer.parseInt(elemtos[1]);
                Elemento temp = new Elemento(contenido, documento);
                if (actual == documento) 
                {
                    if(verificar_Existente(contenido))
                    {
                        Vocabulario_por_Documento.add(temp);
                    }
                }
                else
                {   
                    actual = documento;
                    Vocabulario.add(Vocabulario_por_Documento);
                    Vocabulario_por_Documento = new ArrayList<>();
                    Vocabulario_por_Documento.add(temp);

                }
            }
            Vocabulario.add(Vocabulario_por_Documento);
            // Cerramos el archivo
            entrada.close();
            
            File file = new File(input);
            file.delete();
            
            N = Vocabulario.size();
            crear_VocabularioGeneral();
            archivo_vocabulario();
            archivo_postings();
        }catch (Exception e){
            System.err.println("Ocurrio un error: " + e.getMessage());
        }
    }
    
    public void archivo_vocabulario()
    {
        BufferedWriter writer = null;

        String input = "D:\\Vocabulario.txt";
        try{    
            writer = new BufferedWriter( new FileWriter( input));
            int inicio = 0;
            int docs = 0;
            for (int i = 0; i < Vocabulario_general.size(); i++) {
                    Elemento_General elemento = Vocabulario_general.get(i);
                    String t = elemento.contenido;                
                    inicio += docs;
                    docs = elemento.apariciones;
                    String Final = t+";"+docs+";"+inicio+"\n";
                    writer.write(Final);
            }
            writer.close();

        }catch(Exception s)
        {
            System.out.println(s);
        }
    }    
    
    public void archivo_postings()
    {         
        for (int i = 0; i < Vocabulario_general.size(); i++) {
                Elemento_General elemento = Vocabulario_general.get(i);
                String t = elemento.contenido;  
                int apariciones = elemento.apariciones;
                recorrer_vocabulario(t, apariciones);
        }
    }
    
    public void recorrer_vocabulario(String contenido, int apariciones)
    {
        BufferedWriter writer = null;
        String input = "D:\\Postings.txt";
        
        try
        {
            writer = new BufferedWriter( new FileWriter( input, true));            
            for (int i = 0; i < Vocabulario.size(); i++) {
                ArrayList documento = Vocabulario.get(i);
                for (int j = 0; j < documento.size(); j++) {
                    Elemento elemento = (Elemento) documento.get(j);
                    if(elemento.contenido.equals(contenido))
                    {
                        float x = ((float)N/(float)apariciones);
                        double idf = (Math.log10(x) / Math.log10(2));
                        double tf = 1 + (Math.log10((float)elemento.apariciones) / Math.log10(2));
                        double peso = idf * tf;
                        String docid = elemento.documento+"";
                        String Final = docid+";"+peso+"\n";
                        writer.write(Final);
                    }
                }   
            }
            writer.close();
        }
        catch(Exception s)
        {
        }
    }
    
    public void crear_VocabularioGeneral()
    {
        for (int i = 0; i < Vocabulario.size(); i++) {
            ArrayList temp = Vocabulario.get(i);
            for (int j = 0; j < temp.size(); j++) {
                Elemento elemento = (Elemento) temp.get(j);                
                String contenido = elemento.contenido;
                if(verificar_Existente_General(contenido))
                {
                    Vocabulario_general.add(new Elemento_General(contenido));
                }
            }            
        }
    }
    
    public boolean verificar_Existente_General(String contenido)
    {
        for (int i = 0; i < Vocabulario_general.size(); i++) {
            Elemento_General temp = Vocabulario_general.get(i);
            if(temp.contenido.equals(contenido)){
                temp.apariciones++;
                return false;
            }
        }
        return true;
    }
 
    public boolean verificar_Existente(String contenido)
    {
        for (int i = 0; i < Vocabulario_por_Documento.size(); i++) {
            Elemento temp = Vocabulario_por_Documento.get(i);
            if(temp.contenido.equals(contenido)){
                temp.apariciones++;
                return false;
            }
        }
        return true;
    }
    
    
    
}
