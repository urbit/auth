import "@urbit/foundation-design-system/styles/globals.css";
import React, {Component} from "react";
import Urbit from "@urbit/http-api";
import classNames from 'classnames';
import LockLineIcon from 'remixicon-react/LockLineIcon';
import LockUnlockLineIcon from 'remixicon-react/LockUnlockLineIcon';

class App extends Component {

  constructor(props) {
    super(props);
    window.urbit = new Urbit("");
    window.urbit.ship = window.ship;
    this.state = {open: new Map(), err: false};
    window.urbit.onError = () => this.setErr(true);
    window.urbit.onOpen = () => this.setErr(false);
  };

  componentDidMount() {
    this.subOpen();
  };

  reset = async () => {
    window.urbit.reset();
    window.urbit.scry({
      app: "auth-client",
      path: "/check"
    }).then(
      () => {
        this.subOpen();
        this.setErr(false);
      },
      () => console.log("connection error")
    )
  };

  subOpen = () => {
    window.urbit.subscribe({
      app: "auth-client",
      path: "/open",
      event: this.handleUpdate
    })
  };

  handleUpdate = u => {
    const open = this.state.open;
    if ("new" in u) {
      if (u.new.entry.result === "got") {
        this.setState({open: open.set(u.new.ref, u.new.entry)})
      }
    } else if ("close" in u) {
      open.delete(u.close.ref);
      this.setState({open: open});
    } else if ("open" in u) {
      this.setState({open: new Map(u.open.reverse())})
    }
  };

  setErr = e => {
    if (e) console.log("connection error");
    this.setState({err: e});
  };

  reconnect = () => {
    const err = this.state.err;
    return (
      (err) &&
        <button
          className="button-sm bg-red text-wall-100 fixed z-10 bottom-2 right-2"
          onClick={() => this.reset()}
        >
          Reconnect
        </button>
    )
  };

  choose = (ref, ent, choice) => {
    const open = this.state.open;
    ent.result = (choice) ? "yes" : "no";
    window.urbit.poke({
      app: "auth-client",
      mark: "auth-do",
      json: {
        ref: ref,
        approve: choice
      }
    });
    this.setState({open: open.set(ref, ent)});
  }

  entries = () => {
    const open = this.state.open;
    const arr = Array.from(open).reverse();
    return (
      <div className="max-w-md flex flex-col gap-6 h-full box-border mx-auto">
        {
          (arr.length === 0)
            ? <div className="my-auto text-xl text-center">
                No pending authentication requests found.
              </div>
            : <>{arr.map(this.entry)}<div className="mb-auto">&nbsp;</div></>
        }
      </div>
    )
  };

  entry = ([ref, ent]) => {
    const cl = classNames(
      "first:mt-auto",
      "bg-wall-100",
      "rounded-xl",
      "p-5",
      "grid",
      "grid-cols-6",
      "grid-flow-row-dense",
      "gap-4",
      {"opacity-50": (ent.result !== "got")}
    );
    return (
      <div key={ref} className={cl}>
        {this.domain(ent.request.turf)}
        {this.icon(ent.status)}
        {this.username(ent.request.user)}
        {this.code(ent.request.code)}
        {
          this.message(
            ent.request.msg,
            (ent.request.user !== null),
            (ent.request.code !== null)
          )
        }
        {this.buttons(ref, ent)}
        {this.info(ent.status)}
      </div>
    )
  };

  domain = turf => {
    const cl = classNames(
      "font-mono",
      "overflow-x-hidden",
      "text-ellipsis",
      "font-medium",
      "text-xl",
      "col-start-1",
      "col-end-6"
    );
    return (
      <span className={cl}>{turf}</span>
    )
  };

  icon = status => {
    const lock = (status === "ok" || status === "old");
    const cl = classNames(
      "ri-2x",
      "col-start-6",
      "col-end-7",
      {
        "text-green-400": (status === "ok"),
        "text-yellow-400": (status === "old"),
        "text-red": (status !== "ok" && status !== "old"),
      }
    );
    return (
      <div className={cl}>
        {
          (lock) ?
            <LockLineIcon size="2em" className="ml-auto"/>
          : <LockUnlockLineIcon size="2em" className="ml-auto"/>
        }
      </div>
    )
  };

  username = u =>
  (u !== null) &&
    <div className="pl-2 col-start-1 col-end-5 flex flex-col items-start">
      <span className="font-mono text-ellipsis text-xl">{u}</span>
      <span className="text-xs text-wall-500">user</span>
    </div>

  code = n => {
    const cl = classNames(
      "row-start-2",
      "row-end-3",
      "col-start-5",
      "col-end-7",
      "flex",
      "flex-col",
      "items-end",
      "pr-2"
    );
    return (
      (n !== null) &&
        <div className={cl}>
          <span className="font-mono text-ellipsis text-xl">{n}</span>
          <span className="text-xs text-wall-500">code</span>
        </div>
    )
  };

  message = (m, usr, cod) => {
    const cl = classNames(
      "col-start-1",
      "flex",
      "flex-col",
      "items-start",
      "gap-1",
      "pl-2",
      {
        "col-span-full": (usr || !cod),
        "col-span-4": (!usr && cod),
        "pr-2": (usr || !cod)
      }
    );
    return (
      (m !== null) &&
        <div className={cl}>
          <span className="text-base text-ellipsis text-sm">{m}</span>
          <span className="text-xs text-wall-500">msg</span>
        </div>
    )
  };

  buttons = (ref, ent) => {
    const yesCl = classNames(
      "button-lg",
      "bg-green-400",
      "text-white",
      {"hover:opacity-100": (ent.result !== "got")}
    );
    const noCl = classNames(
      "button-lg",
      "bg-wall-100",
      "border-2",
      "border-wall-500",
      {"hover:opacity-100": (ent.result !== "got")}
    );
    return (
      <div className="col-start-1 col-span-full flex justify-evenly my-2">
        <button
          onClick={() => this.choose(ref, ent, true)}
          className={yesCl}
          disabled={(ent.result !== "got")}
        >
          Approve
        </button>
        <button
          onClick={() => this.choose(ref, ent, false)}
          className={noCl}
          disabled={(ent.result !== "got")}
        >
          Deny
        </button>
      </div>
    )
  };

  info = status =>
  <div className="col-start-1 col-span-full text-wall-500 text-xs">
    {
      (status === "ok")
      ? <span>
          This request is
          <span className="text-green-400 font-medium"> AUTHENTIC </span>
          and comes from the URL shown.
        </span>
      : (status === "bad")
      ? <span>
          <span className="text-red font-medium">WARNING: </span>
          the signature for this request does not match.
          This request may not come from the URL shown.
        </span>
      : (status === "old")
      ? <span>
          <span className="text-yellow-400 font-medium">ALERT: </span>
          the signature for this request is for an outdated key revision.
          This request may not come from the URL shown.
        </span>
      : (status === "old-bad")
      ? <span>
          <span className="text-red font-medium">WARNING: </span>
          the signature for this request does not match, and is also
          for an outdated key revision. This request may not come from
          the URL shown.
        </span>
      : <span>
          <span className="text-red font-medium">WARNING: </span>
          the signature for this request could not be verified.
          This request may not come from the URL shown.
        </span>
    }
  </div>

  render() {
    return (
      <>
        {this.reconnect()}
        <main className="h-full w-full">
          {this.entries()}
        </main>
      </>
    )
  }
};

export default App;
