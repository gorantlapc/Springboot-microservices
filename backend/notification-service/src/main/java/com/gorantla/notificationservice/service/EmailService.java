package com.gorantla.notificationservice.service;

import com.gorantla.notificationservice.data.Message;
import io.awspring.cloud.sqs.annotation.SqsListener;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;


@Service
public class EmailService {
    private static final Logger logger = org.slf4j.LoggerFactory.getLogger(EmailService.class);

    @Value("${spring.mail.username}")
    private String fromEmail;

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @SqsListener(value = "${sqs.queue.name}")
    public void listenForEmailEvents(Message message) {
        // Logic to process email events from aws sqs
        switch (message.orderStatus()) {
            case ORDER_CREATED -> sendEmail(message.orderRequest().userEmail(),
                    "Order Notification",
                    "Your order with ID " + message.orderRequest().orderId() + " with " + message.orderRequest().price() + " has been processed.");
            case ORDER_CANCELLED -> sendEmail(message.orderRequest().userEmail(),
                    "Order Cancellation",
                    "Your order with ID " + message.orderRequest().orderId() + " has been cancelled.");
            case ORDER_UPDATED -> System.out.println("Received email event from Kafka");
            default -> System.out.println("Unknown event type: " + message.orderStatus());
        }
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
            logger.error( "Failed to send HTML email to {}", to, e);
        }
    }
}
