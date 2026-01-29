package com.gorantla.notificationservice.service;

import com.gorantla.notificationservice.data.Message;
import io.awspring.cloud.sqs.annotation.SqsListener;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.SendEmailRequest;

@Service
public class EmailService {
    private static final Logger logger = org.slf4j.LoggerFactory.getLogger(EmailService.class);

    @Value("${ses.from.address}")
    private String fromEmail;

    private final SesClient sesClient;

    public EmailService(SesClient sesClient) {
        this.sesClient = sesClient;
    }

    @SqsListener(value = "${sqs.queue.name}")
    public void listenForEmailEvents(Message message) {
        // Logic to process email events from aws sqs
        logger.info("Processing order message with OrderID {} from SQS", message.orderRequest().orderId());
        try {
            switch (message.orderStatus()) {
                case ORDER_CREATED -> sendEmail(message.orderRequest().userEmail(),
                        "Order Notification",
                        "Your order with ID " + message.orderRequest().orderId() + " with " + message.orderRequest().price() + " has been processed.");
                case ORDER_CANCELLED -> sendEmail(message.orderRequest().userEmail(),
                        "Order Cancellation",
                        "Your order with ID " + message.orderRequest().orderId() + " has been cancelled.");
                case ORDER_UPDATED -> System.out.println("Received email event from SNS ");
                default -> System.out.println("Unknown event type: " + message.orderStatus());
            }
        } catch (Exception e) {
            logger.error("Error processing message from SQS: {}", e.getMessage());
        }
    }

    private void sendEmail(String to, String subject, String body) {
        // Implementation for sending email
        SendEmailRequest emailRequest = SendEmailRequest.builder()
                .source(fromEmail)
                .destination(builder -> builder.toAddresses(to))
                .message(builder -> builder
                        .subject(subBuilder -> subBuilder.data(subject))
                        .body(bodyBuilder -> bodyBuilder.text(textBuilder -> textBuilder.data(body)))
                )
                .build();
        logger.info("Sending email to : {}", to);
        sesClient.sendEmail(emailRequest);
    }

}
