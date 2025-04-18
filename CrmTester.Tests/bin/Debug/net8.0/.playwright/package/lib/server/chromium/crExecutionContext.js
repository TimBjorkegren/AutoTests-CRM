"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.CRExecutionContext = void 0;
exports.createHandle = createHandle;
var _assert = require("../../utils/isomorphic/assert");
var _crProtocolHelper = require("./crProtocolHelper");
var _stackTrace = require("../../utils/isomorphic/stackTrace");
var _utilityScriptSerializers = require("../isomorphic/utilityScriptSerializers");
var js = _interopRequireWildcard(require("../javascript"));
var dom = _interopRequireWildcard(require("../dom"));
var _protocolError = require("../protocolError");
function _getRequireWildcardCache(e) { if ("function" != typeof WeakMap) return null; var r = new WeakMap(), t = new WeakMap(); return (_getRequireWildcardCache = function (e) { return e ? t : r; })(e); }
function _interopRequireWildcard(e, r) { if (!r && e && e.__esModule) return e; if (null === e || "object" != typeof e && "function" != typeof e) return { default: e }; var t = _getRequireWildcardCache(r); if (t && t.has(e)) return t.get(e); var n = { __proto__: null }, a = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var u in e) if ("default" !== u && {}.hasOwnProperty.call(e, u)) { var i = a ? Object.getOwnPropertyDescriptor(e, u) : null; i && (i.get || i.set) ? Object.defineProperty(n, u, i) : n[u] = e[u]; } return n.default = e, t && t.set(e, n), n; }
/**
 * Copyright 2017 Google Inc. All rights reserved.
 * Modifications copyright (c) Microsoft Corporation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class CRExecutionContext {
  constructor(client, contextPayload) {
    this._client = void 0;
    this._contextId = void 0;
    this._client = client;
    this._contextId = contextPayload.id;
  }
  async rawEvaluateJSON(expression) {
    const {
      exceptionDetails,
      result: remoteObject
    } = await this._client.send('Runtime.evaluate', {
      expression,
      contextId: this._contextId,
      returnByValue: true
    }).catch(rewriteError);
    if (exceptionDetails) throw new js.JavaScriptErrorInEvaluate((0, _crProtocolHelper.getExceptionMessage)(exceptionDetails));
    return remoteObject.value;
  }
  async rawEvaluateHandle(context, expression) {
    const {
      exceptionDetails,
      result: remoteObject
    } = await this._client.send('Runtime.evaluate', {
      expression,
      contextId: this._contextId
    }).catch(rewriteError);
    if (exceptionDetails) throw new js.JavaScriptErrorInEvaluate((0, _crProtocolHelper.getExceptionMessage)(exceptionDetails));
    return createHandle(context, remoteObject);
  }
  async evaluateWithArguments(expression, returnByValue, utilityScript, values, handles) {
    const {
      exceptionDetails,
      result: remoteObject
    } = await this._client.send('Runtime.callFunctionOn', {
      functionDeclaration: expression,
      objectId: utilityScript._objectId,
      arguments: [{
        objectId: utilityScript._objectId
      }, ...values.map(value => ({
        value
      })), ...handles.map(handle => ({
        objectId: handle._objectId
      }))],
      returnByValue,
      awaitPromise: true,
      userGesture: true
    }).catch(rewriteError);
    if (exceptionDetails) throw new js.JavaScriptErrorInEvaluate((0, _crProtocolHelper.getExceptionMessage)(exceptionDetails));
    return returnByValue ? (0, _utilityScriptSerializers.parseEvaluationResultValue)(remoteObject.value) : createHandle(utilityScript._context, remoteObject);
  }
  async getProperties(object) {
    const response = await this._client.send('Runtime.getProperties', {
      objectId: object._objectId,
      ownProperties: true
    });
    const result = new Map();
    for (const property of response.result) {
      if (!property.enumerable || !property.value) continue;
      result.set(property.name, createHandle(object._context, property.value));
    }
    return result;
  }
  async releaseHandle(handle) {
    if (!handle._objectId) return;
    await (0, _crProtocolHelper.releaseObject)(this._client, handle._objectId);
  }
}
exports.CRExecutionContext = CRExecutionContext;
function rewriteError(error) {
  if (error.message.includes('Object reference chain is too long')) throw new Error('Cannot serialize result: object reference chain is too long.');
  if (error.message.includes('Object couldn\'t be returned by value')) return {
    result: {
      type: 'undefined'
    }
  };
  if (error instanceof TypeError && error.message.startsWith('Converting circular structure to JSON')) (0, _stackTrace.rewriteErrorMessage)(error, error.message + ' Are you passing a nested JSHandle?');
  if (!js.isJavaScriptErrorInEvaluate(error) && !(0, _protocolError.isSessionClosedError)(error)) throw new Error('Execution context was destroyed, most likely because of a navigation.');
  throw error;
}
function potentiallyUnserializableValue(remoteObject) {
  const value = remoteObject.value;
  const unserializableValue = remoteObject.unserializableValue;
  return unserializableValue ? js.parseUnserializableValue(unserializableValue) : value;
}
function renderPreview(object) {
  if (object.type === 'undefined') return 'undefined';
  if ('value' in object) return String(object.value);
  if (object.unserializableValue) return String(object.unserializableValue);
  if (object.description === 'Object' && object.preview) {
    const tokens = [];
    for (const {
      name,
      value
    } of object.preview.properties) tokens.push(`${name}: ${value}`);
    return `{${tokens.join(', ')}}`;
  }
  if (object.subtype === 'array' && object.preview) return js.sparseArrayToString(object.preview.properties);
  return object.description;
}
function createHandle(context, remoteObject) {
  if (remoteObject.subtype === 'node') {
    (0, _assert.assert)(context instanceof dom.FrameExecutionContext);
    return new dom.ElementHandle(context, remoteObject.objectId);
  }
  return new js.JSHandle(context, remoteObject.subtype || remoteObject.type, renderPreview(remoteObject), remoteObject.objectId, potentiallyUnserializableValue(remoteObject));
}