#include <stdio.h>
#include <stdlib.h>
#include<math.h>

void decimal_llu_binario(unsigned long long d){
    int orden[64];
    for(int i=0; i<64; i++){
        if(d%2==1){
            orden[63-i]=1;
        }
        else{
            orden[63-i]=0;
        }
        d=d>>1;
    }
    for(int i=0; i<64; i++){
        printf("%d", orden[i]);
    }
    printf("\n");
}

unsigned long long kmer_canonico_prueba(unsigned long long kmer){

    unsigned long long c[] = {0x3333333333333333,0x0F0F0F0F0F0F0F0F,0x00FF00FF00FF00FF, 0x0000FFFF0000FFFF};

    unsigned long long k0, k1, k2, k3, k4, k5, k6;


    k0= ((kmer>>2)&c[0]) | ((kmer&c[0])<<2); //k0

    k1= ((k0>>4)&c[1]) | ((k0&c[1])<<4); //k1


    k2=  ((k1>>8)&c[2]) | ((k1&c[2])<<8);  //k2

    k3=  ((k2>>16)&c[3]) | ((k2&c[3])<<16); //k3

    k4= (k3>>32) | (k3<<32);

    k5 =  ~k4;                     //k5

    k6 =  k5>>2;                   //k6

    if(k6 < kmer){
        return k6;
    }
    else{
        return kmer;
    }
}

unsigned long long MurMurHash3( unsigned long long kmer_canon){

    unsigned long long k, k2, k5;

    k = kmer_canon>>33; //k0
    k = k^kmer_canon;   //k1
    k2 = 0xff51afd7ed558ccd*k; //k2
    k = k2>>33; //k3
    k = k^k2; //k4
    k5 = 0xc4ceb9fe1a85ec53*k; //k5
    k = k5>>33; //k6
    k = k^k5; //h

    return k;
}

unsigned long long array_to_longlong(int L, int almacenamiento_bits[L]){

    unsigned long long kmer=0, kmer_save;
    int corrimiento;

    for(int i=0; i<L; i++){

        corrimiento=2*(-i+(L-1));
        kmer_save=kmer;
        kmer= (unsigned long long) almacenamiento_bits[i]<<corrimiento;
        kmer=kmer+kmer_save; //separamos la operacion ya que c no soporta una operacion logica junto con una aritmetica

    }
    return kmer;
}
///Esta funcion la voy a cambiar, me falta hacer la busqueda binaria
int find_msb(unsigned long long num) {
    int msb=0, i=1, c;

    while(msb==0){
        c=64-i;
        msb=num>>c;
        i+=1;
    }

    return (i-2);

}

float HLL_estimation(int m, int sketch[m]){

    double Z=0, alpha, C_HILL, producto;

    for(int i=0; i<m; i++){
        Z= (double) Z + 1/(pow(2, sketch[i]));
    }

    alpha= (double) 0.7213/(1+(1.079/m));

    C_HILL= (double) alpha*(pow(m,2)/Z);


    if(C_HILL <= (2.5*m)){
        ///Calculo nz
        int nz=0;
        for(int i=0; i<m; i++){
            if(sketch[i]==0){
               nz+=1;
            }//if2
        }//for
        producto=(double) m/nz;
        C_HILL= (double) m*log10(producto);
        //printf("Se uso factor de correccion.\n");
    }//

    return C_HILL;

}

float cardinalidad(FILE *archivo){

    int L_k=31; ///Largo kmer


    unsigned long long kmer, kmer_canonico_var, MurMurHash3_var, indice;

    int m=16384, sketch[m];

    ///Llenamos sketch vacio con ceros
    for(int i=0; i<m; i++){
        sketch[i]=0;
    }

    int almacenamiento_bits[L_k],entero, confirmacion,
        end_loop=1, i_principal=0; //variables loop
    while(end_loop){
        ///Cocificacion genoma
        confirmacion = fseek(archivo, i_principal, SEEK_SET);


        ///Deteccion errores
        if(confirmacion!=0){
            printf("error en fseek");
        }
        ///Obtención de string de 31 letras y codificacion en 2 bits
        for(int i=0; i<L_k && end_loop==1; i++){
            entero= (int) fgetc(archivo);
            switch(entero){
                case 65: entero=0; //A
                        break;
                case 67: entero=1; //c
                        break;
                case 71: entero=2; //G
                        break;
                case 84: entero=3; //T
                        break;
                case 10: i_principal=i_principal+L_k-1; //salto de linea: largo_kmer+iteracion+2, hay un +1 al final que compensa
                         break;

                case -1: end_loop=0;//detener programa
                         break;
            }
            if(end_loop==1 ){
                almacenamiento_bits[i]=entero;
            }
        }//for entero


        if(end_loop==1 && entero!=10){
            unsigned long long kmer;
            kmer = array_to_longlong(L_k, almacenamiento_bits);
            //decimal_llu_binario(kmer);
        //kmer= codificacion_genoma(L_k, archivo, i);
        ///buckets
        ///Almacenamiento de array de 31 bases nitrogenadas en variable de 64 bits, obtencion funcion canonica y Mmh3
            kmer_canonico_var= kmer_canonico_prueba(kmer);
            MurMurHash3_var=MurMurHash3(kmer_canonico_var);
        ///Guardamos en sketch
            indice= MurMurHash3_var & 0x3FFF;
            sketch[indice]=find_msb(MurMurHash3_var)+1;
        }

///Iterador principal

        i_principal=i_principal+1;
    }//for_principio


    //Estimacion HLL
    double C_HILL;
    C_HILL = HLL_estimation(m, sketch);

    ///Cierre archivo
    fclose(archivo);

    return C_HILL;

}

int main()
{
    ///Genoma 1
    FILE *archivo_1;
    ///Abre archivo para lectura
    archivo_1 = fopen("genoma1.txt", "r");///<------- modificar con cambio de genoma
    ///Deteccion errores
    if (archivo_1 == NULL){
        printf("error al abrir archivo");
    }
    ///Genoma 2
    FILE *archivo_2;
    ///Abre archivo para lectura
    archivo_2 = fopen("genoma2.txt", "r");///<------- modificar con cambio de genoma
    ///Deteccion errores
    if (archivo_2 == NULL){
        printf("error al abrir archivo");
    }
    ///Genoma 3
    FILE *archivo_3;
    ///Abre archivo para lectura
    archivo_3 = fopen("genoma3.txt", "r");///<------- modificar con cambio de genoma
    ///Deteccion errores
    if (archivo_3 == NULL){
        printf("error al abrir archivo");
    }
    ///Genoma 4
    FILE *archivo_4;
    ///Abre archivo para lectura
    archivo_4 = fopen("genoma4.txt", "r");///<------- modificar con cambio de genoma
    ///Deteccion errores
    if (archivo_4 == NULL){
        printf("error al abrir archivo");
    }

    double C_hill_1, C_hill_2, C_hill_3, C_hill_4;
    C_hill_1=cardinalidad(archivo_1);
    C_hill_2=cardinalidad(archivo_2);
    C_hill_3=cardinalidad(archivo_3);
    C_hill_4=cardinalidad(archivo_4);

    ///Resultados
    printf("Calculo de diferentes cardinalidades:\nC_hill_1 = %.0lf\nC_hill_2 = %.0lf\nC_hill_3 = %.0lf\nC_hill_4 = %.0lf\n", C_hill_1, C_hill_2, C_hill_3, C_hill_4);

    printf("\nNo pude realizar el calculo del resto de los genomas ya que no se como trabajar con mas de un Sketch.\n");

    return 0;
}
