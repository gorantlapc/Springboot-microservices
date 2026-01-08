package com.gorantla.notificationservice.component;

import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

@Component("notificationMailSender")
public class MailSender {

    @Value("${spring.mail.username}")
    private String fromEmail;

    private final JavaMailSender mailSender;

    public MailSender(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendEmail(String to, String subject, String body) {
        // Implementation for sending email
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject(subject);
        message.setText(body);
        message.setFrom(fromEmail);
        mailSender.send(message);
    }

    public void sendHtmlEmail(String to, String subject, String htmlBody) {
        // Implementation for sending HTML email
        // This is a placeholder; actual implementation would use MimeMessageHelper
        MimeMessage mimeMailMessage = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(mimeMailMessage, "utf-8");
        try {
            helper.setText(htmlBody, true); // true indicates HTML
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setFrom(fromEmail);
            mailSender.send(mimeMailMessage);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
