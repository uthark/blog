---
title: How to add YAML support to go-restful
date: 2018-01-22
categories:
- development
- golang
tags:
- golang
- yaml
- go-restful
twitter:
  image:
---

[go-restful] is a [go] package used for building REST-style web services.
It is potent, but it supports JSON and XML out of the box only. Fortunately, go-restful allows registering custom serialization schemes.

To do so, it provides a handy interface [EntityReaderWriter], which contains only two methods:

``` go
// EntityReaderWriter can read and write values using an encoding such as JSON,XML.
type EntityReaderWriter interface {
    // Read a serialized version of the value from the request.
    // The Request may have a decompressing reader. Depends on Content-Encoding.
    Read(req *Request, v interface{}) error

    // Write a serialized version of the value on the response.
    // The Response may have a compressing writer. Depends on Accept-Encoding.
    // status should be a valid HTTP status code
    Write(resp *Response, status int, v interface{}) error
}
```

What we need to do is to implement this interface and register it in go-restful.

Let’s implement the interface:

``` go
package restyaml

import (
	"io"
	"io/ioutil"

	"github.com/emicklei/go-restful"
	"gopkg.in/yaml.v2"
)

// MediaTypeApplicationYaml is a Mime Type for YAML.
const MediaTypeApplicationYaml = "application/x-yaml"

// YamlReaderWriter implements EntityReaderWriter for YAML objects to be used by restful.
type YamlReaderWriter struct {
	contentType string
}

// NewYamlReaderWriter creates new instance.
func NewYamlReaderWriter(contentType string) restful.EntityReaderWriter {
	return YamlReaderWriter{contentType: contentType}
}

func closeWithErrHandle(c io.Closer) {
	err := c.Close()
	if err != nil {
		logger.Println("Unable to close resource: ", err)
	}
}

// Read a serialized version of the value from the request.
// The Request may have a decompressing reader. Depends on Content-Encoding.
func (e YamlReaderWriter) Read(req *restful.Request, v interface{}) error {
	defer closeWithErrHandle(req.Request.Body)
	bytes, err := ioutil.ReadAll(req.Request.Body)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(bytes, v)
	return err
}

// Write a serialized version of the value on the response.
// The Response may have a compressing writer. Depends on Accept-Encoding.
// status should be a valid Http Status code
func (e YamlReaderWriter) Write(resp *restful.Response, status int, v interface{}) error {
	bytes, err := yaml.Marshal(v)
	if err != nil {
		return err
	}

	resp.WriteHeader(status)
	_, err = resp.Write(bytes)
	return err
}

```

For implementing actual reading/writing of YAML, I use a library called [go-yaml]. The implementation is straightforward; call [`Marshal`](https://godoc.org/gopkg.in/yaml.v2#Marshal) and [`Unmarshal`](https://godoc.org/gopkg.in/yaml.v2#Unmarshal) methods and do an error processing.

The final step is registering the newly written `YamlReaderWriter` in the go-restful container during application startup.

``` go

package rest

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"bitbucket.org/uthark/yttrium/internal/config"
	"bitbucket.org/uthark/yttrium/internal/mime"
	"github.com/emicklei/go-restful"
)

// Init initializes server.
func init() {

	restful.SetLogger(logger)
	restful.DefaultResponseContentType(restful.MIME_JSON)
	restful.RegisterEntityAccessor(restyaml.MediaTypeApplicationYaml, restyaml.NewYamlReaderWriter(restyaml.MediaTypeApplicationYaml))

	// register web-services in restful and start http…
	// omitted for brevity
}

```

Now, we can submit requests in YAML format to our API:

``` sh
$ curl -H "Accept: application/x-yaml" http://localhost:8080/task
- id: dd453ac9-6e8d-4f37-88a9-4e6d5b653e8d
  name: Another Task
  dateAdded: 2018-01-20T20:05:09.378Z
  dateCompleted: 0001-01-01T00:00:00Z
```

If we don’t specify the header, the output will be in JSON:

``` sh
$ curl http://localhost:8080/task
[
  {
   "id": "dd453ac9-6e8d-4f37-88a9-4e6d5b653e8d",
   "name": "Another Task",
   "dateAdded": "2018-01-20T20:05:09.378Z",
   "dateCompleted": "0001-01-01T00:00:00Z"
  }
 ]
```

[go-restful]: https://github.com/emicklei/go-restful
[go]: https://golang.org
[EntityReaderWriter]: https://godoc.org/github.com/emicklei/go-restful#EntityReaderWriter
[go-yaml]: https://github.com/go-yaml/yaml
