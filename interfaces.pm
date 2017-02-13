#!/usr/bin/perl
=head1 Proyecto Final PERL
=item
  Integrantes:
=cut
use strict;
package interfaces;
use HTML::Template;
use parent 'CGI::Application';
#use CGI::Application::Plugin::Forward;
#use CGI ':standard';
use GD::Graph::bars;
use GD::Text;
#use Data::Dumper;

my (%hashIP,%hashEvento);

sub setup {
  my $self = shift;
  $self->run_modes(
    'menu'  =>  'menu',
  ); 
  $self->start_mode('menu');
  #$self->mode_param('selector');
}
sub menu{
  my $output;
  my $template = HTML::Template->new(filename => './graf.tmpl');
  my $info=&open_dir("reportes");
  my %datos;
  $datos{"ip"}=$info->[0];
  $datos{"evento"}=$info->[1];
  $template->param(\%datos);
  $output.=$template->output();
  return $output;    
}
=item
  Subrutina open_dir, recibe como parametro
  el directorio donde se encuentran los CSV.
=cut
sub open_dir{
  my $hash;
  my @graficas;
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
      my @fileCSV= split /\./,$filename;
      if( lc $fileCSV[-1] eq "csv"){ ##valida que sea un archivo csv
        &obtiene_ip($file,$fileCSV[0]); ## Llama a grafica_ip
      }
    }		
  }
  push(@graficas,&grafica_ip());
  push(@graficas,&grafica_evento());
  return \@graficas;
}
=item
  Subrutina obtiene_ip, obtiene las IP'S del CSV
  y cuenta los eventos de cada ip, recibe como
  parametro la ruta del archivo y el nombre del
  archivo en ese orden.
=cut
sub obtiene_ip {
  my $pathname=$_[0];
  my $filename=$_[1];
  my $num_eventos=0;
  my $detIP=0; ## Contador para detectar el campo IP
  my $banderaIP=0; ## bandera que indica que detecto el campo IP
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
        $num_eventos++;
      }else{
        $num_eventos++;
        $hashIP{"$datos[$detIP]"}=1; # si no eciste la agrega e inicializa en uno.
      }
    }
  }
  my @filecsv= split /-/,$filename;
  $hashEvento{$filecsv[-3]}=$num_eventos; 
}

sub grafica_ip{
  #ciclo for que ordena por IP (llave del hashIP)
  # print '%hashIP {\n';
  my (@campos, @valores);
  for (sort keys %hashIP){ 
    if($hashIP{$_}>1){
      #agrega a valores las coincidencias de IP's
      push (@valores,$hashIP{$_});
      #Agrega a campos las IP's
      push (@campos,$_);
      # print "  $_ => $hashIP{$_}\n";
    }
  }
  # print "}\n";
  my $tam=keys %hashIP;
  my $max=0;
  foreach(values %hashIP){
    if($_>$max){
      $max=$_;
    }
  }
  my @graf = (\@campos, \@valores);
  my $grafico = GD::Graph::bars->new($tam+200, 720);
  $grafico->set(
    show_values => 1,
    x_label => 'IP\'s',
    bar_width  => '2',
    bar_spacing => '1',
    x_labels_vertical => 1,
    y_label => 'ocurrencias',
    y_max_value   => $max+1,
    title => 'Ips con mas de un evento',
  ) or warn $grafico->error;

  my $imagen = $grafico->plot(\@graf) or die $grafico->error;
  open(IMG, ">ip.png") or die $!;
  binmode IMG;
  print IMG $imagen->png;
  return "ip.png";
}
sub grafica_evento{
  my(@campos, @valores);
  #print '%hashEvento {\n';
  for (sort keys %hashEvento){ 
    if($hashEvento{$_}>1){
      push (@valores,$hashEvento{$_});
      push (@campos,$_);
   #   print "  $_ => $hashEvento{$_}\n";
    }
  }
  #print "}\n";
  my $tam=keys %hashEvento;
  my $max=0;
  foreach(values %hashEvento){
    if($_>$max){
      $max=$_;
    }
  }
  my @graf = (\@campos, \@valores);
  my ($width,$bar_width);
  if ($tam<1280){
    $width=1280;
    $bar_width=(1280-200)/$tam;
  }else{
    $width=($tam*5)+200;
    $bar_width=4;
  }
  #print "bar_width: $bar_width\n";
  my $grafico = GD::Graph::bars->new($width, $width-100);
  $grafico->set(
    show_values => 1,
    x_label => 'IP\'s',
    bar_width  => $bar_width,
    bar_spacing => '1',
    y_max_value   => $max+2,
    x_labels_vertical => 1,
    y_label => 'ocurrencias',
    title => 'Eventos',
  ) or warn $grafico->error;
  my $imagen = $grafico->plot(\@graf) or die $grafico->error;
  open(IMG, ">evento.png") or die $!;
  binmode IMG;
  print IMG $imagen->png;
  return "evento.png";
}
1
