#!/usr/bin/perl
=head1 Proyecto Final PERL
=item
  Integrantes:
=cut
use warnings;
use strict;
use CGI ':standard';
use GD::Graph::bars;
use Data::Dumper;

=item
  Subrutina open_dir, recibe como parametro
  el directorio donde se encuentran los CSV.
=cut
sub open_dir{
  my $hash;
  my ($path) = ($_[0]);
  opendir(DIR, $path) or die $!; #se abre el directorio
  my @files = grep(!/^\./,readdir(DIR));
  closedir(DIR);
  foreach my $file (@files){
    my $filename=$file;
    $file = $path.'/'.$file; #path absoluto del fichero o directorio
    next unless( -f $file or -d $file ); #se rechazan pipes, links, etc ..
    if( -d $file){
      last;
      #open_dir($file,$hash);
    }else{
      my @fileCSV= split /\./,$file;
      if( lc $fileCSV[-1] eq "csv"){ ##valida que sea un archivo csv
        &grafica_ip($file,$filename); ## Llama a grafica_ip
      }
    }		
  }
}
=item
  Subrutina grafica_ip, obtiene las IP'S del CSV
  y cuenta los eventos de cada ip, recibe como
  parametro la ruta del archivo y el nombre del
  archivo en ese orden.
=cut
sub grafica_ip{
  my $pathname=$_[0];
  my $filename=$_[1];
  my $detIP=0; ## Contador para detectar el campo IP
  my $banderaIP=0; ## bandera que indica que detecto el campo IP
  my (@campos, @valores,%hashIP); 
  open FILE,"<",$pathname or die "Error al leer archivo: ",$_[0];
  my @file=(<FILE>);
  close FILE;
  for my $title(@file){
    my @datos=split /,/,$title; #El archivo CSV esta separado por comas.
    if($banderaIP==0){ ## bandera que indica si se encontro el titulo IP
      foreach my $tit(@datos){ #iteracion para encontrar el titulo IP
        if ($tit eq "ip") { #condicion para encontrar a IP
          $banderaIP=1; # si encontro la coincidencia con IP se asigna uno a la bandera ip
          last; # sale del for
        }else{
          $detIP++; #mientras no encuentra la coincidencia con IP incrementa.
        }
      }
    
    }else{ ## Ya encontro el indice donde se encutra IP
      if(exists $hashIP{$datos[$detIP]}){ #valida si existe la llave con la ip
        $hashIP{$datos[$detIP]}++; #si existe incrementa en uno la coincidencia con esa ip
      }else{
        $hashIP{"$datos[$detIP]"}=1; # si no eciste la agrega e inicializa en uno.
      }
    }
  }
  #ciclo for que ordena por IP (llave del hashIP)
  for (sort keys %hashIP){ 
    #agrega a valores las coincidencias de IP's
    push (@valores,$hashIP{$_});
    #Agrega a campos las IP's
    push (@campos,$_);
  }
  my @graf = (\@campos, \@valores);
  my $grafico = GD::Graph::bars->new(750, 520);
  $grafico->set(
    x_label => 'IP\'s',
    bar_width  => '15',
    bar_spacing => '2',
    x_labels_vertical => 1,
    y_label => 'ocurrencias',
    title => $filename,
  ) or warn $grafico->error;

  my $imagen = $grafico->plot(\@graf) or die $grafico->error;
  $filename=$filename.'.png';
  open(IMG, ">$filename") or die $!;
  binmode IMG;
  print IMG $imagen->png;
}
&open_dir("./reportes");
#&grafica_ip("./reportes/2017-02-09-blacklist-unam-asn.csv","017-02-09-blacklist-unam-asn.csv");
