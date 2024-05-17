import { HttpFunction } from "@google-cloud/functions-framework";
import { PubSub } from "@google-cloud/pubsub";
import { Request, Response } from "express";
import jwt from "jsonwebtoken";

class AuthError extends Error {
  statusCode: number;
  authentication: string;

  constructor(authResponse: AuthResponse, statusCode: number = 401) {
    super(authResponse.message);
    this.statusCode = statusCode;
    this.authentication = authResponse.authentication;
  }
}

interface TokenPayload {
  doctorId: string;
  doctorName?: string;
  fullName?: string;
}
enum AuthOperation {
  Succeed = "succeed",
  Fail = "fail",
}

interface AuthResponse {
  authentication: AuthOperation;
  pubsubMessageId?: number;
  message: string;
  tokenPayload?: TokenPayload;
}

interface Body {
  topicId: string;
  imageIndex: number;
  storageBucketPath: string;
}

export const handlePostRequest: HttpFunction = async (
  req: Request,
  res: Response
) => {
  if (req.method === "POST") {
    try {
      let authResponse: AuthResponse;
      const webhookTopicId = process.env.WEBHOOK_TOPIC_ID;
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret || !webhookTopicId) {
        authResponse = {
          authentication: AuthOperation.Fail,
          message: "No JWT secret or webhook topic ID provided",
        };
        throw new AuthError(authResponse);
      }

      const data = req.body as Body;
      const headers = req.headers;
      if (!headers && headers["auth-token"]) {
        authResponse = {
          authentication: AuthOperation.Fail,
          message: "No token provided",
        };
        throw new AuthError(authResponse);
      }
      const authToken = headers["auth-token"] as string;

      const tokenPayload = jwt.verify(
        authToken as string,
        jwtSecret
      ) as TokenPayload;

      // Publish message to Pub/Sub
      const pubSubClient = new PubSub();

      const messageBuffer = Buffer.from(
        JSON.stringify({
          path: data.storageBucketPath,
          index: data.imageIndex,
          topic: data.topicId,
        })
      );

      const messageId = await pubSubClient
        .topic(webhookTopicId)
        .publishMessage({
          data: messageBuffer,
          attributes: {
            "auth-token": authToken,
          },
        });

      authResponse = {
        authentication: AuthOperation.Succeed,
        message: `Successfully authenticate user with ID ${tokenPayload.doctorId} & published message with ID ${messageId}`,
      };

      res.status(200).json(authResponse);
    } catch (error) {
      if (error instanceof AuthError) {
        res.status(error.statusCode).json({
          message: error.message,
          authentication: error.authentication,
        });
      } else if (error instanceof Error) {
        res.status(500).json({ message: error.message });
      } else {
        res.status(500).json({ message: "An unknown error occurred" });
      }
    }
  } else {
    res.status(405).send({ error: "Method not allowed" });
  }
};
