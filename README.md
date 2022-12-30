# No Code Social Cross Posting

This repo contains an Azure Logic App and supporting Azure infrastructure that can be used to provide a cross-posting service for content to go to LinkedIn, Mastodon and Twitter.

You send a simple JSON request to the HTTP endpoint created by the Logic App once deployed. This will then be echoed to the three listed services. Make sure to [read the associated blog post](https://blog.siliconvalve.com/2022/12/20/cross-posting-blog-posts-to-mastodon-twitter-and-linkedin-using-azure-logic-apps/) that covers any setup required.

An Azure Key Vault holds a single secret - your Mastodon API key - which is used at run time for posting to the platform. Make sure to override the `mastodon_host` parameter when deploying the Logic App as your host may differ from the default.

**Note:** the Logic App is deployed to a Consumption plan.

### Sample JSON request

POST a request using the body format shown to the Logic App's published HTTP endpoint.

```json
{
 "Title": "Cross-posting blog posts to Mastodon, Twitter and LinkedIn using Azure Logic Apps",
 "Summary": "In this post I take a look at how you can use the power of no-code Azure Logic Apps to build a cross-posting service for Mastodon, Twitter and LinkedIn.",
 "ImageRef": "https://siliconvalve.files.wordpress.com/2022/12/2022-12-19_17-25-35-1.png",
 "Link": "https://blog.siliconvalve.com/2022/12/20/cross-posting-blog-posts-to-mastodon-twitter-and-linkedin-using-azure-logic-apps"
}
```

### Deployed Logic App

![Picture of resulting Azure Logic App](https://siliconvalve.files.wordpress.com/2022/12/2022-12-19_17-25-35-1.png "Azure Logic App")
