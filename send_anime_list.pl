#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use XML::Simple;
use Email::MIME;
use Email::MIME::Creator;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use utf8;
use Encode;

my $api = "http://cal.syoboi.jp/cal_chk.php?usr=hoge&days=1";

my $ua = LWP::UserAgent->new;
my $xml = XML::Simple->new;

my $response = $ua->get($api);

if ($response->is_success) {
    my $html = $response->content;
    my $data = $xml->XMLin($html);

    my $body = "本日放送予定のアニメ一覧\n\n";

    for (my $i = 0; $i < $#{$data->{ProgItems}->{ProgItem}} ; $i++) {
        my $rItme = $data->{ProgItems}->{ProgItem}->[$i];
        my $StTime = check_date($rItme->{StTime});
        my $EdTime = check_date($rItme->{EdTime});
        $body .= "【$StTime～$EdTime】";
        $body .= "$rItme->{ChName}\n";
        $body .= "$rItme->{Title} ";
        unless ($rItme->{Count} eq "") {
            $body .= "第$rItme->{Count}話";
        }
        if ($rItme->{SubTitle} eq "") {
            $body .= "「サブタイトル未定」";
        } else {
            $body .= "「$rItme->{SubTitle}」";
        }
        if ($rItme->{ProgComment} eq "") {
            $body .= "\n\n";
        } else {
            $body .= "\n※$rItme->{ProgComment}\n\n";
        }
    }
    send_to_mail($body);
} else {
    die $response->status_line;
}

sub send_to_mail {
    my $utf8 = find_encoding('utf8');

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    my $today = sprintf("%04d%02d%02d", $year + 1900, $mon + 1, $mday);

    my $from = '';
    my $to = '';
    my $subject = "Today's Anime Lists [$today]";
    my $body = shift;
    my $smtp_host = '';

    my $email = Email::MIME->create(
        header => [
            From    => $from,
            To      => $to,
            Subject => $subject,
        ],
        attributes => {
            content_type => 'text/plain',
            charset      => 'UTF-8',
            encoding     => 'base64',
        },
        body => $utf8->encode($body),
    );

    my $smtp = Email::Sender::Transport::SMTP->new({
        host => $smtp_host,
    });

    eval {
        sendmail($email, { 'transport' => $smtp });
    };
    print $@;
}

sub check_date {
    my $time = shift;
    my $hour = substr($time, 8, 2);
    my $min = substr($time, 10, 2);
    return "$hour:$min";
}

1;
