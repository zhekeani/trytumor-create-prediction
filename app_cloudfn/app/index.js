"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handlePostRequest = void 0;
const pubsub_1 = require("@google-cloud/pubsub");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
class AuthError extends Error {
    constructor(authResponse, statusCode = 401) {
        super(authResponse.message);
        this.statusCode = statusCode;
        this.authentication = authResponse.authentication;
    }
}
var AuthOperation;
(function (AuthOperation) {
    AuthOperation["Succeed"] = "succeed";
    AuthOperation["Fail"] = "fail";
})(AuthOperation || (AuthOperation = {}));
const handlePostRequest = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    if (req.method === "POST") {
        try {
            let authResponse;
            const webhookTopicId = process.env.WEBHOOK_TOPIC_ID;
            const jwtSecret = process.env.JWT_SECRET;
            if (!jwtSecret || !webhookTopicId) {
                authResponse = {
                    authentication: AuthOperation.Fail,
                    message: "No JWT secret or webhook topic ID provided",
                };
                throw new AuthError(authResponse);
            }
            const data = req.body;
            const headers = req.headers;
            if (!headers && headers["auth-token"]) {
                authResponse = {
                    authentication: AuthOperation.Fail,
                    message: "No token provided",
                };
                throw new AuthError(authResponse);
            }
            const authToken = headers["auth-token"];
            const tokenPayload = jsonwebtoken_1.default.verify(authToken, jwtSecret);
            // Publish message to Pub/Sub
            const pubSubClient = new pubsub_1.PubSub();
            const messageBuffer = Buffer.from(JSON.stringify({
                path: data.storageBucketPath,
                index: data.imageIndex,
                topic: data.topicId,
            }));
            const messageId = yield pubSubClient
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
        }
        catch (error) {
            if (error instanceof AuthError) {
                res.status(error.statusCode).json({
                    message: error.message,
                    authentication: error.authentication,
                });
            }
            else if (error instanceof Error) {
                res.status(500).json({ message: error.message });
            }
            else {
                res.status(500).json({ message: "An unknown error occurred" });
            }
        }
    }
    else {
        res.status(405).send({ error: "Method not allowed" });
    }
});
exports.handlePostRequest = handlePostRequest;
