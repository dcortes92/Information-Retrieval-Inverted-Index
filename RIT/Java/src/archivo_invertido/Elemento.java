/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package archivo_invertido;

/**
 *
 * @author SirIsaac
 */
public class Elemento {
    String contenido;
    int apariciones = 1;
    int documento;

    public Elemento(String contenido, int documento) {
        this.contenido = contenido;
        this.documento = documento;
    }
    
}
